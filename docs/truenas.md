
# Post-install setup

- Set up accounts
- - Truenas Scale: `Credentials` → `Local Users`
- - Truenas Core: `Accounts` → `Users`
- - Allow `sudo` for root
- - Set `bash` as shell for all users that you care about

# Startup script

This script makes sure that the following things are configured properly:
- Disk TLER
- Swap is disabled
- Disk spin-down is disabled
- - ¿ do we need to make an exception for NVMe disks ?
- DHCP is forcefully enabled

Edit the script to disable things you don't need.

Installation:

- Get script here: [truenas-startup.sh](./truenas-startup.sh)
- Copy script into `/data/truenas-startup.sh`
- Go to `System Settings` → `Advanced` → `Init/Shutdown Scripts`.
- Add `sudo bash /data/truenas-startup.sh` at Post-init stage

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

# Share several pools via a single SMB/samba share

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
