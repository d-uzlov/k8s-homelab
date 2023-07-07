
# Login timeout

Increase to 360 hours (1296000 seconds):
```bash
# Truenas Scale
sed -i 's/auth.generate_token",\[300/auth.generate_token",\[1296000/g'  /usr/share/truenas/webui/*.js

# Truenas Core
sed -ie 's/auth.generate_token",\[300/auth.generate_token",\[1296000/g' /usr/local/www/webui/*.js
```

References:
- https://tomschlick.com/blog/2022/06/28/extend-truenas-web-ui-session-timeout/
- https://www.reddit.com/r/truenas/comments/vn1tu7/extend_truenas_web_ui_session_timeout/

# Disable atime for boot pool

```bash
zfs set atime=off boot-pool
zfs set relatime=off boot-pool
mount | grep boot
```

# Disable swap

```bash
midclt call system.advanced.update '{"swapondrive": 0}'
```

In Truenas Core you can also change this in web-ui:
`system` → `advanced` → `storage` → `swap size in GB`.

There is no option for this in the Truenas Scale web-ui.

# Set up email notifications

https://www.truenas.com/docs/scale/scaletutorials/toptoolbar/settingupsystememail/


You need to set up email both for root and admin accounts.

`alert icon in top right` → `gear` → `email` → `gmail oauth`

# SMART tuning

https://www.smartmontools.org/wiki/Powermode
set smart power management to standby

# Share several pools via SMB

Create bind mount:
```bash
sudo mount --rbind /mnt/main/k8s /mnt/system-mount/shared-links/main
sudo mount --rbind /mnt/ssd/k8s /mnt/system-mount/shared-links/ssd
```

`--bind` creates a reference to one filesystem
`--rbind` is recursive. Useful if you want to mount whole ZFS dataset tree.

To make changes persistent, create startup script.

# Enable apt

```bash
sudo chmod +x /bin/apt /bin/apt-*
```

But it seems like you can't install anything because by default truenas
doesn't have any repositories, except truenas ones.

# Force destroy filesystem

Don't forget to change `/dev/device-name` to your device.

```bash
dd if=/dev/zero of=/dev/device-name bs=1M count=1
```

Warning! This will immediately destroy all data without any user prompts.
