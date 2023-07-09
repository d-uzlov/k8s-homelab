
# Reformat NVMe drive to use 4k sectors

https://www.bjonnh.net/article/20210721_nvme4k/

```bash
# check if the drive supports 4k sectors
nvme id-ns -H /dev/nvme0n1 | grep "LBA Format"

# format
# either use lbaf=<LBA format index>
nvme format /dev/nvme0n1 --lbaf=1
# or directly use block size
nvme format /dev/nvme0n1 --block-size=4096

# check that sector size changed
nvme id-ns -H /dev/nvme0n1 | grep "LBA Format"
```

# Check sector size on Windows

```ps
fsutil fsinfo sectorinfo C:
```

Look at the `LogicalBytesPerSector` value.

# Disable write cache for A SATA drive

```bash
# replace /dev/sdl with path to your drive
# you can use partitions
hdparm -W 0 /dev/sdl
```

# Setup partitions

```bash
parted

> select /dev/nvme1n1
> unit s print free
> mkpart
> Partition name?  []? p1
> File system type?  [ext2]? zfs
> Start? 2048s
> End? 50%
```

# Use partitions in ZFS

```bash
# find out PARTUUID of a partition
blkid /dev/nvme1n1p1 -s PARTUUID -o value

zpool add -f main log /dev/disk/by-partuuid/your-partuuid-value

# check status
zpool list main -v
```
