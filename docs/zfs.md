
# Checksums

Summary:
- Never disable checksums
- fletcher4 and fletcher2 break nopwrite

References:
- https://openzfs.github.io/openzfs-docs/Basic%20Concepts/Checksums.html
- https://www.reddit.com/r/zfs/comments/8chx6y/comment/dxgv41p/
- - > - SHA-512/256: 50% higher performance than SHA-256 on 64-bit hardware with minimum code changes.
    > - Skein: 80% higher performance than SHA-256 with new and highly secure algorithm. Includes a KCF SW provider interface.
    > - Edon-R: >350% higher performance than SHA-256. Lower security margin than Skein, but much higher throughput.
- https://github.com/openzfs/zfs/pull/12918
- - There are a lot of benchmark references
- - `cat /proc/spl/kstat/zfs/fletcher_4_bench`
- - `cat /proc/spl/kstat/zfs/chksum_bench`
- - For example:
    > implementation   digest    1k        2k        4k        8k        16k       32k       64k       128k      256k      512k      1m
    > fletcher-4       4         3932      7112      11824     18053     24549     28667     32892     35115     36338     36156     36562
    > edonr-generic    256       1775      2017      2206      2317      2376      2379      2398      2429      2424      2418      2398
    > skein-generic    256       786       837       856       878       885       883       887       886       889       886       885
    > sha256-generic   256       368       384       387       399       398       397       400       401       400       400       401
    > sha512-generic   512       532       579       601       624       605       627       631       632       631       632       629
    > blake3-generic   256       271       277       283       279       281       283       283       283       283       283       283
    > blake3-sse2      256       314       1138      1660      1806      1872      1927      1897      1956      1954      1938      1935
    > blake3-sse41     256       324       1249      1830      1991      2116      2185      2168      2209      2220      2211      2214
    > blake3-avx2      256       327       1388      2231      3331      3782      4067      4290      4386      4406      4382      4386
- - All values are in MB/s

# Capacity calculation

https://jro.io/capacity/

# Use partitions in ZFS

```bash

# find out PART UUID of a partition
blkid /dev/nvme1n1p1 -s PARTUUID -o value

sudo zpool add -f main log /dev/disk/by-partuuid/your-partuuid-value

# check status
zpool list main -v

```

# ashift

```bash

# print current ashift
sudo zpool get ashift
# if property ashift is missing, you can try checking zdb
sudo zdb -C | grep ashift

```

# zpool create example

This command creates a ZFS pool with:
- 3 mirrored data vdevs
- 1 mirrored special device
- 1 log device

```bash

sudo zpool create -o ashift=12 -O mountpoint=/mnt/petunia petunia \
mirror \
/dev/disk/by-id/ata-ST12000NM000J-2TY103_ZR305PES-part2 \
/dev/disk/by-id/ata-ST12000NM000J-2TY103_ZR305RBC-part2 \
mirror \
/dev/disk/by-id/ata-ST12000NM001G-2MV103_WAICRTCS-part2 \
/dev/disk/by-id/ata-ST12000NM0007-2A1101_WAICRYDA-part2 \
mirror \
/dev/disk/by-id/ata-HGST_HUH721212ALE600_5PJ54MXE-part2 \
/dev/disk/by-id/ata-TOSHIBA_MG08ACA14TE_41S0A1R5FRVH-part2 \
log \
/dev/disk/by-id/nvme-INTEL_MEMPEK1J016GAL_BTBT849220ZH016N_1-part1 \
special mirror \
/dev/disk/by-id/ata-TEAM_T253480GB_TPBF2209020010803378-part1 \
/dev/disk/by-id/ata-Apacer_AS340_480GB_E09507281ACE00417122-part1

```

# Statistics

```bash

# list pools
zpool list
# list pools with drive info
zpool list -v
# monitoring compression effectiveness
zfs get compressratio
zfs list -r -o space,compressratio
zfs list -t filesystem -r -o space,compressratio

# print statistics for current operations
# see also: zpool help iostat
# print once:
zpool iostat -y rpool
# print separated for different block size:
zpool iostat -y rpool -r
# print average statistics from the start of the system
zpool iostat rpool
# similar to `watch --interval 2 zpool iostat -y rpool`
zpool iostat -y rpool 2

```

# iostat

```bash

sudo apt-get install -y sysstat

# generic linux iostat for drives
iostat -mx 2

```

Columns (from `man 1 iostat`):
- `r/s`: The number (after merges) of read requests completed per second for the device.
- `rrqm/s`: read request merged+queued per second
- `r_await`: The average time (in milliseconds) for read requests issued to the device to be served. This includes the time spent by the requests in queue and the time spent servicing them.
- `w_await`: ... for write requests
- `d_await`: ... for discard requests
- `d/s`: The number (after merges) of discard requests completed per second for the device.
- `f/s`: The  number (after  merges) of flush requests completed per second for the device.
- - This counts flush requests executed by disks.
- - Flush requests are not tracked for partitions.
- - Before being merged, flush operations are counted as writes.
- `aqu-sz`: The average queue length of the requests that were issued to the device.
- `%util`: Percentage  of  elapsed  time during which I/O requests were issued to the device (bandwidth utilization for the device).
- - Device saturation occurs when this value is close to 100% for devices serving requests serially.
- - But for devices serving requests in parallel, such as RAID arrays and modern SSDs, this number does not reflect their performance limits.

# Compression benchmark

References:
- https://github.com/openzfs/zfs/pull/9735#issuecomment-570082078
- [Disk tests](./disk-test/summary.md#disk-sequential-write-test-results)
- https://github.com/openzfs/zfs/issues/406#issuecomment-1225568351
- https://www.reddit.com/r/zfs/comments/rk4q2i/comment/hp960xp/

Summary:
- Never use gzip, lzjb
- Never disable compression
- - nopwrite will stop working
- - Last block will be partially empty but still written
- lz4 has early-abort feature that makes it work better with incompressible data
- zstd and zstd-fast both have roughly the same read speed, regardless of compression complexity
- zstd becomes extremely slow when you increase compression complexity
- zstd-fast is bad (though, maybe it's speed would make up for it on a system with slow CPU)
- - zstd-fast-1: compression ratio is around 1.0
- - zstd-fast-N: compression ratio is significantly worse than zstd-1
- - zstd-fast-N is comparable to lz4
- - All variants are slower than lz4
- Even zstd-3 is very CPU-intensive
- Hight levels of zstd require a lot of memory
- - > When developing zstd support everything above 9 was considered not-feasible and nothing more than a tech demo.
- > you can use "zle" for the compression type to only compress zeros with no other overhead from attempting to compress blocks with an algorithm

Summary 2:
- For generic data use lz4 or zstd-1
- For already compressed data use lz4
- On systems with slow CPU use lz4
- On systems with _extremely_ slow CPU use zle

# TRIM

```bash

# automatic trim
# doesn't do as much as manual trim
zpool get autotrim
sudo zpool set autotrim=on pool_name

# manual trim
sudo zpool trim rpool
zpool status -t

```

# `nopwrite`

To enable:
- Disable encryption
- Use appropriate checksum algorithm
- Enable compression

These commands show if `nopwrite` works:

```bash

zfs --version
# zfs-2.1.5-1ubuntu6~22.04.1
# zfs-kmod-2.1.5-1ubuntu6~22.04.1

dd if=/dev/zero of=/tmp/test-zfs-file bs=100M count=1
sudo zpool create tank /tmp/test-zfs-file
sudo zfs create tank/test
# use sha256 checksum to enable nopwrite
sudo zfs set checksum=sha256 tank/test
sudo zfs set compression=lz4 tank/test
sudo chmod 777 -R /tank

# create a file, check used space
dd if=/dev/urandom of=/tmp/test-random-file bs=1M count=1
cp /tmp/test-random-file /tank/test/
zfs list -t all -r tank/test
# 1M used, 39M available

# create snapshot, rewrite file, check used space
sudo zfs snapshot tank/test@1
cp /tmp/test-random-file /tank/test/
zfs list -t all -r tank/test
# 1M used, 150K in snapshot, 38.8M available

sudo zfs destroy -r tank/test

```

References:
- [checksums](#zfs-checksums)
- https://github.com/openzfs/zfs/blob/d3d63cac4d318da0a7dc23dc5e89366ad940febe/module/zfs/dmu.c#L2076-L2078
- - > Encrypted objects are also
	> not subject to nopwrite since writing the same data will still
	> result in a new ciphertext.

# Encryption

Any dataset can be encrypted or not encrypted.
ZFS doesn't prevent you from creating a non-encrypted dataset inside an encrypted one.

However, Truenas UI has its own opinion about this. It will give you an error if you try.

As noted in the [`nopwrite`](#nopwrite) section, encryption breaks nopwrite.

- https://www.truenas.com/community/threads/confused-by-native-zfs-encryption-some-observations-many-questions.89081/post-620035
- - > There is a caveat concerning native ZFS encryption
    > vs traditional block device encryption: what is exposed to the public.
    > I'll give my own summary understanding comparing three common options:
    >
    > Native ZFS, at rest (or powered off):
    > - Inaccessible
    > - - File Data
    > - - File Names and Properties
    > - - Sizes of individual files (unsure about this one)
    > - - Directory listings and structures
    > - - Logs (if logs are saved here)
    > - Accessible
    > - - Encryption Options and Hashes
    > - - ZFS Metadata and Options
    > - - Number of Files and Blocks (via pointers and inodes) [1]
    > - - Dataset Names
    > - - Snapshot Names
    > - - Free Space
    > - - Used Space

# Set limit for ARC size

```bash

cat /sys/module/zfs/parameters/zfs_arc_min /sys/module/zfs/parameters/zfs_arc_max | numfmt --to=iec

# set 8G for current session
echo 8589934592 | sudo tee /sys/module/zfs/parameters/zfs_arc_min
echo 8589934592 | sudo tee /sys/module/zfs/parameters/zfs_arc_max
# 2G:  2147483648
# 4G:  4294967296
# 8G:  8589934592
# 16G: 17179869184

# set ARC size automatically after boot
sudo tee /etc/modprobe.d/50-zfs_arc_size.conf << EOF
options zfs zfs_arc_min=4294967296
options zfs zfs_arc_max=4294967296
EOF
cat /etc/modprobe.d/50-zfs_arc_size.conf
sudo update-initramfs -u

# purge cache for current system (useful if you want to reduce ARC size)
echo 0 | sudo tee /sys/module/zfs/parameters/zfs_arc_shrinker_limit
echo 3 | sudo tee /proc/sys/vm/drop_caches

```

# L2ARC

L2ARC creates some RAM overhead.
However, despite popular beliefs, this overhead is very small.

The overhead is roughly 70 bytes per record in L2ARC.
This depends on your record size, and file sizes.

Here is my experience with L2ARC RAM overhead, according to arc statistics tool:
- L2ARC size `~100 GiB`, overhead `~5 MiB`
- L2ARC size `~380 GiB`, overhead `~24 MiB`
- L2ARC size `~450 GiB`, overhead `~53 MiB` (without `l2arc_exclude_special`)
- L2ARC size `~600 GiB`, overhead `~54 MiB`
- L2ARC size `~925 GiB`, overhead `~150 MiB`

References:
- https://www.reddit.com/r/zfs/comments/ud1djk/l2arc_overhead_confusion/
- - > The issue of indexing L2ARC consuming too much system RAM
    > was largely mitigated several years ago, when the L2ARC header
    > (the part for each cached record that must be stored in RAM)
    > was reduced from 180 bytes to 70 bytes.
    > For a 1TiB L2ARC, servicing only datasets with the default 128KiB recordsize,
    > this works out to 640MiB of RAM consumed to index the L2ARC
- https://www.reddit.com/r/zfs/comments/sql872/why_you_need_at_least_64gb_of_ram_before/

# L2ARC tuning

```bash

# disable l2 caching for the special metadata device
echo 1 | sudo tee /sys/module/zfs/parameters/l2arc_exclude_special
# set max write speed of l2arc device
# the default speed is just a few MB/s
# this sets average write limit to 100 MB/s, peak to 200 MB/s
echo 209715200 | sudo tee /sys/module/zfs/parameters/l2arc_write_boost
echo 104857600 | sudo tee /sys/module/zfs/parameters/l2arc_write_max

```

# ZFS ARC statistics

```bash

# print statistics
sudo arc_summary
# for ARC only
sudo arc_summary | head -n 97
# for l2arc only
sudo arc_summary | grep L2ARC -A 7 -B 1
# print l2arc tunables
sudo arc_summary | grep l2arc

cat /proc/spl/kstat/zfs/arcstats
arcstat -f read,hits,miss,hit%,miss%,arcsz,c,l2read,l2hits,l2miss,l2hit%,l2miss%,arcsz,l2size 2

```

# List holds

```bash

# list all datasets with at least one hold
zfs get userrefs | grep 'userrefs *[^-\ 0]'

# select one of entries and run zfs holds
zfs holds nvme/test/backup/nvme/k8s/default--test-nvmeof2@zrepl_20250205_031626_000

# run "zfs release tag_name dataset@snapshot" if you need to remove the hold

```

# Change mount point

```bash

# dataset will be mounted on new mount point after this command
zfs set mountpoint=/location pool/dataset

# change, but skip mounting
# useful target dataset or some of its children are busy
# new mountpoint will be used on next boot
zfs set -u mountpoint=/location pool/dataset

```

References:
- https://unix.stackexchange.com/questions/548969/change-the-mount-point-of-a-zfs-dataset-thats-in-use
- https://serverfault.com/questions/1000540/change-zfs-mountpoint-property-without-remounting/1148641#1148641

# Send/receive

```bash

# zfs send requires a snapshot
sudo /usr/sbin/zfs snapshot tank/dataset@send
# send creates a stream of data that can be inflated via zfs receive
# you can transfer it immediately or save to file

# zfs receive requires that parent dataset already exists
sudo zfs create tank2/backup

# -s enables receive_resume_token generation
ssh ssd.tn.lan sudo /usr/sbin/zfs send --verbose tank/dataset@send | ssh ssd-nas.storage.lan sudo zfs receive -s tank2/backup/dataset

# if transfer was interrupted, get receive_resume_token from partially received dataset
zfs get -H -o value receive_resume_token tank2/dataset
resumeToken=
# when using resume token, dataset name must be omitted
ssh ssd.tn.lan sudo /usr/sbin/zfs send --verbose -t $resumeToken | ssh ssd-nas.storage.lan zfs receive -s -v tank2/backup/dataset

```

References:
- https://unix.stackexchange.com/questions/343675/zfs-on-linux-send-receive-resume-on-poor-bad-ssh-connection

# Show size

```bash

zfs list -o space,refer,quota,refquota,volsize,recordsize,compressratio

```

# Run ZFS command without sudo

```bash

username=danil
dataset=tulip

sudo zfs allow \
  $username \
  create,destroy,mount,snapshot,bookmark,hold,receive,release,rename,rollback,send,load-key,diff,@quota,@refquota,@refreservation,@recordsize,@reservation,@sharenfs,@volblocksize,@volmode,@volsize \
  $dataset

```

Note that `zfs create` and `zfs set mountpoint` will still fail because `mount` on linux can't work without root:
https://github.com/openzfs/zfs/discussions/10648

`zfs set sharenfs` will fail for the same reason.
