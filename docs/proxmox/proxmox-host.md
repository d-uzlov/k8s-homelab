
# Proxmox host setup

This file contains some tips for configuring Proxmox host itself.

# Initial setup

```bash
# disable subscription warning
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
# fix apt update
mv /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.disabled
# add sudo for all later commands
apt update && apt install -y sudo
```

Add your user for SSH access: [Create user](../linux-users.md#create-new-user).

Later commands are assumed to be executed from your new user.

```bash
# install utils you will likely need
sudo apt install -y iperf3 htop pipx gcc make stress fio unzip
pipx ensurepath
pipx install s-tui

# configure local terminal to use better fonts
sudo dpkg-reconfigure console-setup
# recommended settings:
# - utf-8
# - Latin1 and Latin5
# - TerminusBold
# - 14x28 or 16x32

# Set host console resolution
# By default the kernel terminal tries to use the biggest available resolution
# which can be really hard to read at resolutions above FHD.
sudo nano /etc/kernel/cmdline
# add `video=1920x1080@60` to the file, or another appropriate resolution
sudo proxmox-boot-tool refresh

# https://askubuntu.com/a/1445347
sudo tee /etc/sysctl.d/0-swap.conf << EOF
vm.swappiness = 0
EOF
sudo sysctl --system
# make sure nothing is overriding swappiness
sudo sysctl vm.swappiness

# enable TRIM
zpool get autotrim
sudo zpool set autotrim=on rpool
# trigger TRIM manually, to make sure the disk is fully clean
sudo zpool trim rpool
zpool status -t
```

**Note**: when configuring SSH, you can (and should) disable SSH password login
but don't disable root login, it is required by many proxmox functions.

References:
- https://www.virtualizationhowto.com/2022/08/proxmox-update-no-subscription-repository-configuration/
- https://forum.proxmox.com/threads/changing-host-console-resolution.12408/
- https://forum.proxmox.com/threads/console-video-resolution-whats-the-right-way.142733/

# Config dir list

References:
- https://www.hungred.com/how-to/list-of-proxmox-important-configuration-files-directory/

# PCI-e passthrough

Summary:
- Kernel args can be edited by `sudo nano /etc/kernel/cmdline`
- - After editing update kernel params: `sudo proxmox-boot-tool refresh`
- - This assumes you selected ZFS when installing proxmox
- On intel CPUs you have to add special kernel arg
- - `intel_iommu=on`
- - This has to be done on all kernels, despite documentation stating that newer kernels don't need it
- If you are using consumer hardware which doesn't fully support PCIe,
you may need to apply a hack to disable safety features:
- - `pcie_acs_override=downstream,multifunction`
- - Be careful with partial passthrough, PCIe devices may talk to each other between VMs
- Sometimes device driver doesn't unbind, and you need to disable device initialization:
- - > - pass the device IDs to the options of the vfio-pci modules by adding
    > - - `options vfio-pci ids=1234:5678,4321:8765`
    > - to a .conf file in `/etc/modprobe.d/`
    > - where `1234:5678` and `4321:8765` are `vendor_id:device_id`, obtained by:
    > - - `lspci -nn`
- - Don't forget to update initramfs: `update-initramfs -u -k all`
- - Check which driver is currently in use:
- - - `lspci -nnk`
- - Apparently, even if you blacklist the driver, `lspci -nnk` still shows that it is used,
    but the device is not available.
- Sometimes issues with passthrough can be fixed by disabling PCIe power management
- - Try to add `pcie_port_pm=off` to kernel params if you are having issues despite correct settings

References:
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_pci_passthrough
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_host_device_passthrough
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_pci_passthrough_update_initramfs
- https://forum.proxmox.com/threads/pcie-passthrough-devices-with-error.128825/
- - Here is a discussion about drivers
- - One of the discussed solutions is to use a different driver version
- https://forum.proxmox.com/threads/intel-i226-v-pci-passthrough-failure.130632/
- - Here is a suggestion to disable PCIe power management

# Check supported x86 capabilities

```bash
/lib64/ld-linux-x86-64.so.2 --help | grep x86
```

# email notifications

Taken from the guide here:
https://gist.github.com/tomdaley92/9315b9326d4589c9652ce0307c9c38a3.
Check the link to see if the guide was updated.

```bash
apt update && apt install -y libsasl2-modules mailutils

# enable 2FA in your google account
# https://myaccount.google.com/security?pli=1
# It's impossible to create app password without 2FA

# Create app password
email=example@gmail.com
pass=examplepassword
echo "smtp.gmail.com $email:$pass" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd # generate /etc/postfix/sasl_passwd.db

# edit email config
 cat << EOF >> /etc/postfix/main.cf
relayhost = smtp.gmail.com:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
smtp_tls_session_cache_timeout = 3600s
EOF

postfix reload

# test if it works
target_email=anotheremail@gmail.com
echo "sample message" | mail -s "sample subject" "$target_email"

# I don't remember why I added this.
# You probably don't need this command.
postconf -e "inet_protocols = ipv4"

# this guide doesn't work for yandex.ru emails
```

# Login issues

```bash
sudo journalctl -b -u pveproxy
sudo systemctl status pveproxy.service
sudo systemctl restart pveproxy.service
```

# Ryzen 1000, 2000, 3000 setup

CPUs based on Zen, Zen+, Zen 2 architectures have a bug which makes them freeze when in the C6 state.

Previously there was a setting in BIOS that could fix it by disabling package C6 state while keeping C6 core state.
But it seems like in later versions of the BIOS this setting was removed.

For now the solution is to completely disable C6 core state:

```bash
# Install dependencies
apt install -y git make g++
```

```bash
git clone https://github.com/joakimkistowski/amd-disable-c6.git
cd amd-disable-c6/
make install

# MSR kernel module is required
# enable module until next reboot
modprobe msr
# auto-enable module at boot time
sh -c "echo msr > /etc/modules-load.d/msr.conf"

systemctl enable amd-disable-c6.service
systemctl start amd-disable-c6.service
```

References:
- https://github.com/joakimkistowski/amd-disable-c6

# UEFI settings

Run on the target system:

```bash
# install dependencies
curl https://sh.rustup.rs -sSf | sh
# reload env before runnenig the next command
cargo install uefisettings
uefisettings
sudo $(which uefisettings)
```

Run on your local PC:

```bash
mkdir -p ./docs/proxmox/env/

node=ryzen.pve.lan
bin=$(ssh -t $node 'bash -ic "which uefisettings"')
bin=${bin/$'\n'}
bin=${bin/$'\r'}
ssh $node sudo -S $bin hii list-questions --json > ./docs/proxmox/env/$node-uefi-questions.tmp.json
jq . ./docs/proxmox/env/$node-uefi-questions.tmp.json > ./docs/proxmox/env/$node-uefi-questions.json
ssh $node sudo -S $bin hii show-ifr > ./docs/proxmox/env/$node-uefi-forms.log
```

References:
- https://github.com/linuxboot/uefisettings
- It seems like currently you can't change any important settings (in 2024Q2):
- - https://github.com/linuxboot/uefisettings/issues/2

# ACME

- `Datacenter` -> `ACME`: Create account and plugin context
- - This menu is available only for root account
- Node -> `System` -> Certificates: add new ACME certificate, choose your plugin

For plugin you need to define a few environment variables in the field `API Data`.

Look into the documentation for the original ACME script for the list of variables for each DNS plugin:
- https://github.com/acmesh-official/acme.sh/wiki/dnsapi

For example:

- DuckDNS: `DuckDNS_Token`
- Dynu: `Dynu_ClientId`, `Dynu_Secret`
- - Get them here: https://www.dynu.com/ControlPanel/APICredentials

**Note**: define environment variables without `export` and without quotes!

```bash
# bad!
export DuckDNS_Token="qwertyuiop"
# good
DuckDNS_Token=qwertyuiop
```

# Huge pages

There isn't a lot of info on best practices with huge pages.

It seems like the default settings in Proxmox are good enough.

```bash
# total huge page usage in the system
cat /proc/meminfo | grep Huge
# current huge page usage per VM
sudo grep -e AnonHugePages /proc/*/smaps | awk '{ if($2>4) print $0} ' | awk -F "/" '{print $0; system("ps -fp " $3)} '

cat /sys/kernel/mm/transparent_hugepage/enabled
#   recommended [madvise]

cat /sys/kernel/mm/transparent_hugepage/defrag
#   recommended either [defer+madvise] or [madvise]
```

References:
- https://forum.level1techs.com/t/proxmox-slow-ram-in-windows-vm/167075/13
- https://mathiashueber.com/configuring-hugepages-use-virtual-machine/
- https://docs.renderex.ae/posts/Enabling-hugepages/

# Add second bootable drive

Add second device permanently, or temporarily, or migrate to a different boot device.

```bash
# find what disk you are currently using
zpool status rpool
# example: nvme-eui.34333630524469720025384300000001-part3
# strip the -part3 and use it as disk id

old_disk=
# example: old_disk=/dev/disk/by-id/nvme-eui.34333630524469720025384300000001
new_disk=
# example: old_disk=/dev/disk/by-id/ata-PLEXTOR_PX-128M5S_P02313102798

# show partition table
sudo sgdisk --print $old_disk

# === When disks are similar ===
# works only if disks have the same size and sector size
sudo sgdisk --backup $(basename $old_disk).table $old_disk
sudo sgdisk --load-backup $(basename $old_disk).table $new_disk
sudo sgdisk --randomize-guids $new_disk
sudo sgdisk --print $new_disk

# === When disks are different ===
# in some cases you may need to re-create the partition table manually:
# - if the new disk is smaller, --load-backup will fail
# - if the new disk is bigger, partitions will be too small
# - sgdisk works with sectors, so when going from 512b to 4096b, partition sizes will change 8x
sudo sgdisk --zap-all $new_disk
# For proxmox 8.0 you need 1 GB boot partition, the rest is usually used for ZFS root
# - for 512b sectors
sudo sgdisk --new 1:2048:2099199 --new 2:2099200 $new_disk
# - for 4k sectors
sudo sgdisk --new 1:256:262399 --new 2:262400 $new_disk

sudo sgdisk --print $new_disk

# init boot partition
sudo pve-efiboot-tool format $new_disk-part1 --force
sudo pve-efiboot-tool init $new_disk-part1

# === ZFS mirror ===
# in case you want to add the disk permanently
# disk needs to be the same size or bigger
sudo zpool set autoexpand=off rpool
sudo zpool attach rpool $old_disk-part3 $new_disk-part2

# === Copy zfs to a temporary device ===
sudo zpool create rpool2 $new_disk-part2
# prepare data for transfer
sudo zfs snapshot -r rpool@send1
# overwrite the whole new pool with data from the old disk
sudo zfs send -R rpool@send1 | sudo zfs receive rpool2 -F

sudo pve-efiboot-tool refresh
```

References:
- https://pve.proxmox.com/wiki/ZFS_on_Linux#_zfs_administration
- https://forum.proxmox.com/threads/moving-boot-disk-to-new-disks.105543/
- https://unix.stackexchange.com/questions/263677/how-to-one-way-mirror-an-entire-zfs-pool-to-another-zfs-pool

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

- https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
- https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
- https://github.com/TheGrandWazoo/freenas-proxmox
