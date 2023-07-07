
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

# Disable power saving

Go to `System Settings` → `Services` → `SMART`.

Set `Power mode` to `Standby`.

References:
- https://www.smartmontools.org/wiki/Powermode

# Set up TLER

You can set TLER temporarily:

```bash
# check current TLER timeout
sudo smartctl -l scterc /dev/sdh
# set new timeout
# format is: scterc,<read-timeout-in-deciseconds>,<write-timeout-in-deciseconds>
# it seems like the minimum value is 7 seconds
sudo smartctl -l scterc,70,70 /dev/sdh
```

Or set up a startup script.

Place the script into `/data` to make sure it survives reboots and upgrades.

Go to `System Settings` → `Advanced` → `Init/Shutdown Scripts` and add this script to the list.
Don't forget to run the script with `sudo`.

```bash
#!/bin/sh

# https://github.com/Spearfoot/FreeNAS-scripts/blob/master/set_hdd_erc.sh
# https://www.smartmontools.org/wiki/FAQ#WhatiserrorrecoverycontrolERCandwhyitisimportanttoenableitfortheSATAdisksinRAID

readsetting=70
writesetting=70

get_smart_drives()
{
  gs_drives=$(smartctl --scan | grep "dev" | awk '{print $1}' | sed -e 's/\/dev\///' | tr '\n' ' ')

  gs_smartdrives=""

  for gs_drive in $gs_drives; do
    gs_smart_flag=$(smartctl -i /dev/"$gs_drive" | grep "SMART support is: Enabled" | awk '{print $4}')
    if [ "$gs_smart_flag" = "Enabled" ]; then
      gs_smartdrives=$gs_smartdrives" "${gs_drive}
    fi
  done

  eval "$1=\$gs_smartdrives"
}

drives=""
get_smart_drives drives

set_erc()
{
  echo "Drive: /dev/$1"
  smartctl -q silent -l scterc,"${readsetting}","${writesetting}" /dev/"$1"
  smartctl -l scterc /dev/"$1" | grep "SCT\|Write\|Read"
}

for drive in $drives; do
  set_erc "$drive"
done
```

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

- ! Warning ! This will immediately destroy all data without any user prompts.
