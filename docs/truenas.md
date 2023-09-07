
# Post-install setup

- Setup startup script
- - Get script here: [truenas-startup.sh](./truenas-startup.sh)
- - Copy script into `/data/truenas-startup.sh`
- - Truenas Scale: `System Settings` → `Advanced` → `Init/Shutdown Scripts`.
- - Truenas Core: `Tasks` → `Init/Shutdown Scripts`
- - Add `sudo bash /data/truenas-startup.sh` at Post-init stage
- Set up accounts
- - Truenas Scale: `Credentials` → `Local Users`
- - Truenas Core: `Accounts` → `Users`
- - Allow `sudo` for root
- - Set `bash` as shell for all users that you care about

# Set up email notifications

You need to set up email both for root and admin accounts.

`alert icon in top right` → `gear` → `email` → `gmail oauth`

References:
- https://www.truenas.com/docs/scale/scaletutorials/toptoolbar/settingupsystememail/

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

function list_smart_drives() (
  for drive in $(smartctl --scan | grep "dev" | awk '{print $1}'); do
    smartctl -i "$drive" | grep "SMART support is: Enabled" > /dev/null && echo "${drive}"
  done
)

function set_erc() (
  echo "Configuring drive: $1"
  readsetting=70
  writesetting=70
  smartctl -q silent -l scterc,"${readsetting}","${writesetting}" "$1"
  smartctl -l scterc "$1" | grep "SCT\|Write\|Read"
)

( for drive in $(list_smart_drives); do; set_erc "$drive"; done; )
```

# Share several pools via SMB

Create bind mount:
```bash
sudo mkdir -p /mnt/system/shared-links/main
sudo mkdir -p /mnt/system/shared-links/ssd
sudo mount --rbind /mnt/main/k8s /mnt/system/shared-links/main
sudo mount --rbind /mnt/ssd/k8s /mnt/system/shared-links/ssd
```

- `--bind` creates a reference to one filesystem
- `--rbind` is recursive. Useful if you want to mount whole ZFS dataset tree.

To make changes persistent, create startup script.

# Enable apt

```bash
sudo chmod +x /bin/apt* /bin/dpkg
```

But it seems like there is not much you can install
because by default truenas uses its custom repositories.

# Force destroy filesystem

Don't forget to change `/dev/device-name` to your device.

```bash
dd if=/dev/zero of=/dev/device-name bs=1M count=1
```

- ! Warning ! This will immediately destroy all data without any user prompts.

# Force user access to an SMB share

```conf
force user = 65534
```
