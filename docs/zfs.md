
# Increase max ARC size

```bash
sudo nano /etc/modprobe.d/zfs.conf
options zfs zfs_arc_max=<memory_size_in_bytes>
sudo update-initramfs -u
reboot
```

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

# Capacity calculation

https://jro.io/capacity/

# Statistics

```bash
zpool list -v
zfs get compressratio
zfs list -t filesystem -r -o space,compressratio main-pool
zpool iostat -v 5
iostat -mx 5
```

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
- - zstd-fast-N is comparable to zl4
- - All variants are slower than lz4
- Even zstd-3 is very CPU-intensive
- Hight levels of zstd require a lot of memory
- - > When developing zstd support everything above 9 was considered not-feasible and nothing more than a tech demo.
- > you can use "zle" for the compression type to only compress zeros with no other overhead from attempting to compress blocks with an algorithm

Summary 2:
- On systems with slow CPU use lz4
- For already compressed data use lz4
- For generic data use zstd-1

# TRIM

```bash
# automatic trim
# doesn't do as much as manual trim
zpool get autotrim
zpool list
zpool set autotrim=on <pool-name>

# manual trim
zpool trim rpool
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
sudo zfs set checksum=sha256 tank/test
sudo zfs set compression=lz4 tank/test
sudo chmod 777 -R /tank

dd if=/dev/urandom of=/tmp/test-random-file bs=1M count=1
cp /tmp/test-random-file /tank/test/
zfs list -t all -r tank/test
# 1M used, 39M available

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

Any dataset can be encrypted on not encrypted.
ZFS doesn't prevent you from creating an non-encrypted dataset inside encrypted one.

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
