
# Increase ZFS max arc size

```bash
sudo nano /etc/modprobe.d/zfs.conf
options zfs zfs_arc_max=<memory_size_in_bytes>
sudo update-initramfs -u
reboot
```

# ZFS checksums

https://openzfs.github.io/openzfs-docs/Basic%20Concepts/Checksums.html

# ZFS capacity

https://jro.io/capacity/

# Statistics

```bash
zpool list -v
zfs get compressratio
zfs list -t filesystem -r -o space,compressratio main-pool
zpool iostat -v 5
iostat -mx 5
```

# ZFS benchmark

https://github.com/openzfs/zfs/pull/9735#issuecomment-570082078

# zfs trim

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
