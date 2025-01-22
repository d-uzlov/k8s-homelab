
# OpenWRT in Proxmox

In this guide, we install and configure an OpenWRT virtual router on Proxmox.

# Sources

- [OpenWRT initial setup guide (in Russian)](https://kiberlis.ru/proxmox-openwrt/)
- [OpenWRT DHCP configuration](https://openwrt.org/docs/guide-user/base-system/dhcp)

# Create a virtual machine

Important settings when creating a VM:

- `OS` → `Do not use any media`
- `System` → select `SeaBIOS` (OVMF/UEFI is not supported by OpenWRT)
- `Disks` → remove the default disk
- `Memory` → set 256 MiB.

IF needed, add more network interfaces.

# Allow access via non-private IPs

By default OpenWRT disables web UI access if it thinks you are accessing it from WAN.
If you are running OpenWRT behind an external firewall,
there is usually no reason to do it.

For example, when using `netbird`, it assigns a CGNAT address to client,
which prevents you from using web UI via VPN.

You can fix the issue like this:

```bash
uci set uhttpd.main.rfc1918_filter=0
uci show uhttpd.main
uci commit uhttpd
/etc/init.d/uhttpd restart
```

References:
- https://openwrt.org/docs/guide-user/services/webserver/uhttpd

# Add OpenWRT disk to a VM

OpenWRT doesn't have installation disks,
you need to download and import a disk image.

Run in the Proxmox bash shell:

```bash
# set to your OpenWRT VM ID
vmid=
# set to your storage
# default is local-zfs
storage=local-zfs
# check newer releases here: https://downloads.openwrt.org/releases/
openwrtUrl="https://downloads.openwrt.org/releases/23.05.5/targets/x86/generic/openwrt-23.05.5-x86-generic-generic-ext4-combined.img.gz"
openwrtImg=openwrt-23.05.5-x86-generic-generic-ext4-combined.img

wget "$openwrtUrl"
gunzip ${openwrtImg}.gz
qm importdisk $vmid $openwrtImg $storage
```

In the VM `Hardware` tab edit `Unused Disk 0`:

- Click `Add` to activate imported disk
- `Disk Action` → `Resize` → `Size Increment (GiB)` → `2`.
- - OS will need to be configured to actually use the full disk space

Change the boot order:

- `Options` tab → `Boot Order`.
- Enable the new disk, disable other options

# Initial network setup

You need this to access OpenWRT in your LAN.

Run in the Proxmox console for the VM:

```bash
uci set network.lan.ipaddr=X.X.X.X
# example: uci set network.lan.ipaddr=10.7.0.1
uci set network.lan.netmask=255.255.0.0

# if your openwrt has LAN and WAN ports, skip this
# if your openwrt has only the LAN port, set it up to access the internet
uci set network.lan.gateway=10.0.0.1
uci set network.lan.dns="8.8.8.8 8.8.4.4"

uci commit network
/etc/init.d/network restart
```

At this point you can connect to OpenWRT from LAN via WebUI or SSH.
Default username is `root` with empty password.

If you have LAN and WAN ports, you can set up WAN connection:

```bash
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci set network.wan.hostname='openwrt-outline'

uci commit network
/etc/init.d/network restart
```

# Expand the root partition

Run in the OpenWRT command line:

```bash
opkg update
opkg install parted losetup resize2fs nano
echo -e "ok\nfix" | parted -l ---pretend-input-tty
parted -s /dev/sda resizepart 2 100%
losetup /dev/loop1 /dev/sda2
resize2fs -f /dev/loop1
reboot

# check filesystem after reboot
df -h
```

# Make bash the default shell

```shell
opkg update
opkg install shadow-chsh bash
chsh -s /bin/bash
```

Reconnect to SSH to switch to the new shell.

# Disable DHCP server

OpenWRT has a DHCP server enabled by default. If it isn't the main router in your network,
you have to turn it off to avoid address assignment conflicts:

```shell
uci del dhcp.lan.ra_slaac
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dns_service='0'
uci set dhcp.lan.dynamicdhcp='0'
uci commit network
/etc/init.d/network restart
```
