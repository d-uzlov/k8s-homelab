
# Login timeout

Increase to 360 hours (1296000 seconds):
```bash
sed -i 's/auth.generate_token",\[300/auth.generate_token",\[1296000/g'  /usr/share/truenas/webui/*.js
```

# Disable swap

```bash
midclt call system.advanced.update '{"swapondrive": 0}'
zfs set atime=off boot-pool
zfs set relatime=off boot-pool
mount | grep boot
```

# ZFS tuning

увеличить zfs arc max size
```
sudo nano /etc/modprobe.d/zfs.conf
options zfs zfs_arc_max=<memory_size_in_bytes>
sudo update-initramfs -u
reboot
```

# ZFS checksums

https://openzfs.github.io/openzfs-docs/Basic%20Concepts/Checksums.html

# ZFS capacity

https://jro.io/capacity/

# Set up email notifications

https://www.truenas.com/docs/scale/scaletutorials/toptoolbar/settingupsystememail/

поставить email нужно и для рута, и для админа

alert icon in top right → gear → email → gmail oauth

# SMART tuning

https://www.smartmontools.org/wiki/Powermode
set smart power management to standby

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

# Share several pools via SMB

Create bind mount:
```bash
sudo mount --rbind /mnt/main/k8s /mnt/system-mount/shared-links/main
sudo mount --rbind /mnt/ssd/k8s /mnt/system-mount/shared-links/ssd
```

`--bind` creates a reference to one filesystem
`--rbind` is recursive. Useful if you want to mount whole ZFS dataset tree.

To make changes persistent, create startup script.
