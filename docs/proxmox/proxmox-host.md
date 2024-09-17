
# Proxmox host setup

This file contains some tips for configuring Proxmox host itself.

# Initial setup

Disable subscription warning:

```bash
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
```

`pve-nag-buster` should configure updates automatically. As an alternative:

- `Datacenter / <node-name> / updates / repositories` -> add/enable/disable.
- Disable subscription-only repos
- - `https://enterprise.proxmox.com/debian/ceph-quincy`
- - `https://enterprise.proxmox.com/debian/pve`
- Add a subscription-free repo
- - `http://download.proxmox.com/debian/pve bullseye pve-no-subscription`
- Reference: https://www.virtualizationhowto.com/2022/08/proxmox-update-no-subscription-repository-configuration/

Install useful tools:

```bash
apt install -y sudo
sudo apt install -y iperf3 htop pipx gcc make stress
pipx install s-tui
pipx ensurepath
```

Add your user for SSH access: [SSH docs](../ssh.md).

**Note**: when configuring SSH, you can (and should) disable SSH password login
but don't disable root login, it is required by many proxmox functions.

Configure better font for the host console:

```bash
sudo dpkg-reconfigure console-setup
# `fixed` fond doesn't have high resolutions
# choose VGA or Terminus font to be able to pick a better resolution
```

Set host console resolution

```bash
sudo nano /etc/kernel/cmdline
# add `video=1920x1080@60` to the file, or another appropriate resolution
sudo proxmox-boot-tool refresh
```

References:
- https://forum.proxmox.com/threads/changing-host-console-resolution.12408/
- https://forum.proxmox.com/threads/console-video-resolution-whats-the-right-way.142733/

Enable TRIM:

```bash
zpool get autotrim
sudo zpool set autotrim=on rpool
# trigger TRIM manually, to make sure the disk is fully clean
sudo zpool trim rpool
zpool status -t
```

# Config dir list

References:
- https://www.hungred.com/how-to/list-of-proxmox-important-configuration-files-directory/

# Network: custom MTU

```bash
# get max MTU of your device:
ip -d link | grep maxmtu -B 1
```

Set desired MTU in `<node-name> -> System -> Network / <device-name>`.

Don't forget to set network device MTU to 1 in VM hardware settings.

```bash
# check if your desired MTU is currently allowed in the network
ping -M do -i 0.002 -c 1 -s $((9198 - 28)) 10.0.0.2

# you can set MTU manually for testing
sudo ip link set dev ln_storage mtu 9200
```

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

# LACP status

```bash
cat /proc/net/bonding/bond0
```

# Mellanox ConnectX-3 VLANs

Mellanox ConnectX-3 only supports 126 VLANs.

If you set "VLAN aware" on a bridge in proxmox, proxmox will try to enable VLANs 2-4094,
which is a lot more than 126.
You will see an error like this:

```bash
failed to set vid `{ 127, 128 ... 4093, 4094}`
cmd '/sbin/bridge -force -batch - [vlan add vid 127-4094 dev enp65s0 ]'
failed: No space left on device
```

There are several workarounds:

- Limit VLANs to 2-126
- - Edit bridge in /etc/network/interfaces
```bash
auto vmbr0
iface vmbr0 inet static
  ...
  bridge-vlan-aware yes
  bridge-vids 2-126
```
- Set VLANs you need manually, instead of using a long list
- - Edit bridge in /etc/network/interfaces
```bash
auto vmbr0
iface vmbr0 inet static
  ...
  bridge-vlan-aware yes
  bridge-vids 2 10 50 228 1999
```
- Don't use VLAN aware bridges
- - You can create a separate bridge for a specific VLAN
- - Technically this is similar to defining VLANs you need manually
- - When using Proxmox SDN it already creates special bridges, so just don't set VLAN aware checkbox
- Disable VLAN hardware offloading
- - This may or may not work depending on driver capabilities
- - Edit physical interface in /etc/network/interfaces
```bash
iface enp129s0 inet manual
  rx-vlan-filter off
```

Note that when using VLAN aware bridges VM guests
will receive traffic from all VLANs
which can be a security issue,
and you probably don't want it for most of your VMs.

As mentioned earlier, you can still use VLAN traffic
when using a separate VLAN interface, even without VLAN aware bridge.

References:
- https://forum.proxmox.com/threads/vlan-with-tag-above-126-problem.46072/page-2
- https://forum.proxmox.com/threads/vlan-issues.124714/
- https://www.reddit.com/r/homelab/comments/114ieep/proxmox_bridgevids_option_host_itself_in_vlan/

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
ssh $node sudo -S $bin hii list-questions --json > ./docs/proxmox/env/$node-uefi-questinos.tmp.json
jq . ./docs/proxmox/env/$node-uefi-questinos.tmp.json > ./docs/proxmox/env/$node-uefi-questinos.json
ssh $node sudo -S $bin hii show-ifr > ./docs/proxmox/env/$node-uefi-forms.log
```

References:
- https://github.com/linuxboot/uefisettings
- It seems like currently you can't change any important settings (in 2024Q2):
- - https://github.com/linuxboot/uefisettings/issues/2

# ACME

Usually you need to define a few environment variables in the field `API Data`.

Look into the documentation for the original ACME script for the list of variables for each DNS plugin:
- https://github.com/acmesh-official/acme.sh/wiki/dnsapi

**Note**: define environment variables without `export` and without quotes!

```bash
# bad!
export DuckDNS_Token="askdjhawkjqweeqjw"
# good
DuckDNS_Token=askdjhawkjqweeqjw
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

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

- https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
- https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
- https://github.com/TheGrandWazoo/freenas-proxmox
