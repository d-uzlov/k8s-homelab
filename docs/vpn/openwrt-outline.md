# Outline client on OpenWRT

In this guide, we install and configure an OpenWRT virtual router on Proxmox
and set up the `shadowsocks-libev` Outline/Shadowsocks client.
As a result, all traffic of devices connected to that OpenWRT instance will be routed through Outline.

N.B.: This guide doesn't cover domain-based conditional routing.

# Sources

- [OpenWRT initial setup guide (in Russian)](https://kiberlis.ru/proxmox-openwrt/)
- [shadowsocks-libev setup guide (in Russian)](https://habr.com/ru/articles/748408/)
- [OpenWRT DHCP configuration](https://openwrt.org/docs/guide-user/base-system/dhcp)

# Install OpenWRT

## Create a virtual machine

Start creating a new VM and specify these settings:

- `OS` → `Do not use any media`. At this step click on `Advanced` and make sure that `Start at boot` option is disabled.
- `Disks` → `Disk size (GiB)` → `0,001` (minimum) as we're going to remove it anyway.
- `CPU` → `Type` → `host`.
- `CPU` → `Cores` → `2`.
- `Memory` → `Memory (MiB)` → `256`.
- `Network` → `Firewall` → disable the checkbox.

Click `Finish` and don't start the VM.

## Delete the empty system disk

- Select the OpenWRT VM in the Proxmox web interface and open the `Hardware` tab.
- Highlight the empty disk (most probably `Hard Disk (scsi0)`) and then click `Detach`.
- Once the disk is detached, it will be displayed as `Unused Disk 0`. Choose it and click `Remove`.

## Download OpenWRT image

23.05.5 is the latest stable version of OpenWRT as of September 29, 2024.
The current actual version can be found in the [official OpenWRT repository](https://downloads.openwrt.org/releases/).

Run the following commands in the Proxmox shell.
They download the official OpenWRT disk image, decompress it and import it as a virtual hard disk to the VM. 

```shell
VMID=<your OpenWRT VM ID>
STORAGE=<your Proxmox storage name>
wget https://downloads.openwrt.org/releases/23.05.5/targets/x86/generic/openwrt-23.05.5-x86-generic-generic-ext4-combined.img.gz
gunzip openwrt-23.05.5-x86-generic-generic-ext4-combined.img.gz
mv openwrt-23.05.5-x86-generic-generic-ext4-combined.img openwrt.img
qm importdisk $VMID openwrt.img $STORAGE
rm openwrt.img
```

## Link the new hard disk to the VM

- Select the OpenWRT VM in the Proxmox web interface and open the `Hardware` tab.
- Highlight the new disk (most probably `Unused Disk 0`) and then click `Edit` → `Add`.
- `Disk Action` → `Resize` → `Size Increment (GiB)` → `2`. 
  The OS won't see this extension on boot, so we'll need to expand the root partition explicitly later.

## Add a network interface

- `Hardware` → `Add` → `Network Device`.
- Disable `Firewall`.
- Click `Add`.

## Change the boot order

- `Options` → `Boot Order` → `Edit`.
- Enable the new disk and network interface created on previous steps.
- Move the disk to the top of the list.
- `OK`.

# Set up OpenWRT

- Select the OpenWRT VM in the web interface, click `Start` and open the `Console`.
- As the system prompts you to press `Enter`, activate the shell.

## Set a static IP address

OpenWRT has `192.168.1.1` as the default static IP address.
If you cannot access the VM via this address, or want to change it, type the following in the OpenWRT console:

```shell
uci set network.lan.ipaddr='<X.X.X.X>'
uci commit network
/etc/init.d/network restart
```

Once a static IP is set, you can just use SSH with working copy and paste:

```shell
ssh root@<X.X.X.X>
```

## Expand the root partition

```shell
opkg update
opkg install parted losetup resize2fs
echo -e "ok\nfix" | parted -l ---pretend-input-tty
parted -s /dev/sda resizepart 2 100%
losetup /dev/loop1 /dev/sda2
resize2fs -f /dev/loop1
reboot
```

After reboot, you'll be able to see a plenty of free space on `/`:

```
root@OpenWrt:~# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                 2.1G     15.7M      2.0G   1% /
tmpfs                   119.4M     68.0K    119.3M   0% /tmp
/dev/sda1                15.7M      5.4M     10.0M  35% /boot
/dev/sda1                15.7M      5.4M     10.0M  35% /boot
tmpfs                   512.0K         0    512.0K   0% /dev
```

## Make bash the default shell

```shell
opkg update
opkg install bash
sed 's!/bin/ash!/bin/bash!g' -i /etc/passwd
exit
```

All the next sessions will have bash as the default shell.

# Set up Outline client

```shell
opkg update
opkg install shadowsocks-libev-ss-local shadowsocks-libev-ss-redir
opkg install shadowsocks-libev-ss-rules shadowsocks-libev-ss-tunnel
opkg install luci-app-shadowsocks-libev
opkg install coreutils-base64
```

```shell
ADDRESS='ss://<base64 encoded password and encryption method>@<server IP>:<port>/?outline=1'
ADDRESS_REGEX='ss://([A-Za-z0-9]+)@([.0-9]+):([0-9]+)/\?outline=1'
[[ $ADDRESS =~ $ADDRESS_REGEX ]]
BASE64_PASSWORD=${BASH_REMATCH[1]}
OUTLINE_IP=${BASH_REMATCH[2]}

OUTLINE_PORT=${BASH_REMATCH[3]}
LEFT_PORT=$(($OUTLINE_PORT-1))
RIGHT_PORT=$(($OUTLINE_PORT+1))

METHOD_PASSWORD=$(echo $BASE64_PASSWORD | base64 -d)
PASSWORD_REGEX='([a-z0-9-]+):([A-Za-z0-9]+)'
[[ $METHOD_PASSWORD =~ $PASSWORD_REGEX ]]
OUTLINE_METHOD=${BASH_REMATCH[1]}
OUTLINE_PASSWORD=${BASH_REMATCH[2]}

cat <<EOF > /etc/config/shadowsocks-libev
config server 'sss0'
        option server '$OUTLINE_IP'
        option server_port '$OUTLINE_PORT'
        option password '$OUTLINE_PASSWORD'
        option method '$OUTLINE_METHOD'

config ss_redir 'hj'
        option server 'sss0'
        option local_address '0.0.0.0'
        option local_port '1100'
        option mode 'tcp_and_udp'
        option timeout '60'
        option fast_open '1'
        option reuse_port '1'

config ss_rules 'ss_rules'
        option src_default 'checkdst'
        option dst_forward_recentrst '0'
        option redir_tcp 'hj'
        option redir_udp 'hj'
        option local_default 'forward'
        option dst_default 'forward'
        option nft_tcp_extra 'tcp dport { 80-$LEFT_PORT, $RIGHT_PORT-65535 }'
        option nft_udp_extra 'udp dport { 53-65535 }'
EOF
```

## Disable DHCP server

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

# Check if your Outline client works

```shell
wget -qO- http://ipecho.net/plain | xargs echo
```

You should see the IP of the Outline server.
