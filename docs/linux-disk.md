
# NVMe info

```bash
sudo smartctl -a /dev/nvme0

sudo apt-get install -y nvme-cli
sudo nvme list
sudo nvme id-ctrl /dev/nvme0
# print current power state
sudo nvme get-feature /dev/nvme0 --feature-id 2 --human-readable
# limit maximum power state to 1 (value must be a valid "operational" power state)
sudo nvme set-feature /dev/nvme0 --feature-id 2 --value 1
```

References:
- https://forums.debian.net/viewtopic.php?t=155053

# NVMe sector size

References:
- https://www.bjonnh.net/article/20210721_nvme4k/

```bash
# check if the drive supports 4k sectors
sudo nvme id-ns -H /dev/nvme0n1 | grep "LBA Format"

# format
# !! this will erase all info from the disk !!
# either use lbaf=<LBA format index>
sudo nvme format /dev/nvme0n1 --lbaf=1
# or directly use block size
sudo nvme format /dev/nvme0n1 --block-size=4096

# check that sector size changed
sudo nvme id-ns -H /dev/nvme0n1 | grep "LBA Format"
```

# NVMe namespaces

```bash
sudo nvme list
# nn is the number of supported namespaces
sudo nvme id-ctrl /dev/nvme0 | grep ^nn
# I have yet to see a disk that supports more than 1 namespace
```

References:
- https://narasimhan-v.github.io/2020/06/12/Managing-NVMe-Namespaces.html

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

# Disable write cache for a SATA drive

```bash
# replace /dev/sdl with path to your drive
# you can use partitions
hdparm -W 0 /dev/sdl
```

# Block device info

```bash
# device size in bytes
sudo blockdev --getsize64 /dev/sdb
# device block size
sudo blockdev --getss /dev/sdb
cat /sys/block/sdb/queue/hw_sector_size
cat /sys/block/sdb/queue/physical_block_size

sudo dumpe2fs /dev/sdb
sudo dumpe2fs /dev/sdb | grep "Block size"

sudo apt-get install smartmontools
sudo smartctl -a /dev/sdb

# TRIM / discard support
lsblk -D
cat /sys/block/sdb/queue/discard_max_hw_bytes
cat /sys/block/sdb/queue/discard_granularity
```

# Show current mounts

```bash
cat /proc/mounts
```

# mount NFS

```bash
sudo mkdir -p /mnt/mount-folder
sudo mount -t nfs truenas.lan:/mnt/main/share/name /mnt/mount-folder
```

# Force destroy filesystem

_! Warning ! This will immediately destroy all data without any user prompts._

```bash
# change /dev/device-name to your value
# for example: /dev/sda, /dev/nvme0n1
dd if=/dev/zero of=/dev/device-name bs=1M count=1
```

# cachefilesd for NFS

References:
- https://www.admin-magazine.com/HPC/Articles/Caching-with-CacheFS

```bash
nano /etc/cachefilesd.conf`.

# uncomment RUN=yes to enable
nano /etc/default/cachefilesd

# According to the online Red Hat 7 documentation,
# you need to follow just a couple of rules in setting the caching parameters:
#   0 ≤ bstop < bcull < brun < 100
#   0 ≤ fstop < fcull < frun < 100

sudo systemctl restart cachefilesd
sudo systemctl status cachefilesd

# stats
cat /proc/fs/fscache/stats
ls /var/cache/fscache
cat /proc/fs/nfsfs/servers
cat /proc/fs/nfsfs/volumes

# Cache size
sudo du -sh /var/cache/fscache/
```

# Extend LVM

If you forgot to increase LVM size during installation,
you can do it manually afterwards:

```bash
sudo vgdisplay
sudo lvextend -l +100%FREE /dev/mapper/volume-name
sudo resize2fs /dev/mapper/volume-name
```

# List drives

```bash

lsblk
lsblk -o NAME,SIZE,TYPE,DISC-GRAN,PHY-SEC,LOG-SEC,ROTA,PTTYPE,MOUNTPOINTS
lsblk -o NAME,SIZE,TYPE,DISC-GRAN,PHY-SEC,LOG-SEC,ROTA,PTTYPE,MOUNTPOINTS,PATH
lsblk -o NAME,SIZE,TYPE,DISC-GRAN,PHY-SEC,LOG-SEC,ROTA,PTTYPE,MOUNTPOINTS,PARTUUID,PTUUID,UUID

lsscsi --scsi_id --size

zpool list
zpool status
zpool status -P -s -t -c size
zpool status -P -s -t -c model,size

```

# SATA: Change sector size

For most devices this will not work.

```bash

sudo apt install hdparm
sudo hdparm --set-sector-size 4096 --please-destroy-my-drive /dev/sdc

```
