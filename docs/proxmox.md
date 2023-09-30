
# Initial setup

Enable updates: `<node-name>` -> `updates` -> `repositories` -> `add/enable/disable`.

Disable subscription warning:
```bash
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
```

Set up updates:

- Disable default subscription-only repo: `https://enterprise.proxmox.com/debian/ceph-quincy`
- Add free update repo: `http://download.proxmox.com/debian/pve bullseye pve-no-subscription`
- - Reference: https://www.virtualizationhowto.com/2022/08/proxmox-update-no-subscription-repository-configuration/
- - If you run `pve-nag-buster`, it will be added automatically

# Useful tools

```bash
apt install -y iperf3 htop
```

# Config dir list

References:
- https://www.hungred.com/how-to/list-of-proxmox-important-configuration-files-directory/

# Network

```bash
# get max MTU of your device:
ip -d link | grep maxmtu -B 1

# set MTU for current session
ip link set enxf8e43bd6ac4c mtu 4088

# set MTU permanently
iface enxf8e43bd6ac4c inet manual
        mtu 4088
# or edit in `<node-name>` -> System/Network -> `<device-name>`

# Don't forget to set network device MTU to 1 in VM hardware settings
```

# PCI-e passthrough

Summary:
- Edit kernel args using `nano /etc/kernel/cmdline`
- - After editing update kernel params: `proxmox-boot-tool refresh`
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
    > - to a .conf file in `/etc/modprobe.d/` where `1234:5678` and `4321:8765` are the vendor and device IDs obtained by:
    > - - `lspci -nn`
- - Don't forget to update initramfs: `update-initramfs -u -k all`
- - Check which driver is currently in use:
- - - `lspci -nnk`
- - Apparently, even if you blacklist the driver, `lspci -nnk` still shows that it is used,
    but the device is not available.
- Sometimes issues with passthrough can be fixed by disabling PCIe power management
- - Add `pcie_port_pm=off` to kernel params

References:
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_pci_passthrough
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_host_device_passthrough
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_pci_passthrough_update_initramfs
- https://forum.proxmox.com/threads/pcie-passthrough-devices-with-error.128825/
- - Here is a discussion about drivers
- - One of the discussed solutions is to use a different driver version
- https://forum.proxmox.com/threads/intel-i226-v-pci-passthrough-failure.130632/
- - Here is a suggestion to disable PCIe power management

# Secure boot

When using UEFI, secure boot is enabled by default.
It will prevent you from using the VM for anything interesting.

You can disable it in the BIOS screen, which opens if you press ESC during boot:

# Check x86 capabilities

```bash
/lib64/ld-linux-x86-64.so.2 --help | grep x86
```

# QEMU guest agent

Enable in `<vm-settings>` -> `Options` -> `QEMU Guest Agent`.

Install into VM:
```bash
# Debian / Ubuntu
sudo apt-get -y install qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

# Disk performance

`virtio block` has better performance than `scsi` (aka `virtio scsi`)
but apparently each `virtio block` device consumes a pcie address,
which are apparently limited.

SATA and IDE virtual drives should not be used unless you have compatibility concerns.

References:
- https://forum.proxmox.com/threads/virtio-vs-scsi.52893/

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

# Enable CPU hot-plug in VMs

Inside Linux VM:

```bash
sudo tee /lib/udev/rules.d/80-hotplug-cpu.rules << EOF
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF

# not nessesary
# should fix issues if changes don't apply without reboot
sudo udevadm control --reload-rules && sudo udevadm trigger
```

References:
- [Proxmox documentation about Hot-Plug](https://pve.proxmox.com/wiki/Hotplug_(qemu_disk,nic,cpu,memory)#CPU_and_Memory_Hotplug)

# Login issues

```bash
journalctl -b -u pveproxy
systemctl status pveproxy.service
systemctl restart pveproxy.service
```

# Cluster

- Make sure that your node name resolves to your node IP address
- - `/etc/hosts`
- - Reboot after editing
- Go to `Datacenter -> Cluster -> Create cluster`

Diagnostics:

```bash
/usr/sbin/corosync-cfgtool -s

systemctl status corosync
journalctl -b -u corosync

pvecm status
```

References:
- https://pve.proxmox.com/pve-docs/chapter-pvecm.html#pvecm_edit_corosync_conf

Updating corosync configuration:

```bash
# edit current configuration
nano /etc/pve/corosync.conf
# config changes from /etc/pve/ should propagate to all nodes automatically
# provided you also bump config version field
# but you may need to do it on several nodes if sync doesn't work

# you may need to restart corosync to apply config changes
# you may need to do it on one affected node or on all nodes
systemctl restart corosync
systemctl status corosync
```

# Destroy cluster

- Shows cluster names/list: `pvecm nodes`
- Remove node: `pvecm delnode <NODE_NAME>`

or

```bash
systemctl stop pve-cluster corosync &&
pmxcfs -l &&
rm -rf /etc/corosync/* &&
rm -rf /etc/pve/corosync.conf &&
killall pmxcfs &&
systemctl start pve-cluster

# delete all ssh keys
rm -f /root/.ssh/authorized_keys &&
rm -f /etc/pve/priv/known_hosts &&
rm -f /etc/ssh/ssh_known_hosts &&
systemctl restart ssh.service &&
systemctl restart sshd.service &&
systemctl restart pve-cluster

# delete cached data about other nodes
rm -rf /etc/pve/nodes/node-name/

# don't forget to reboot
reboot now
```

References:
- https://pve.proxmox.com/wiki/Cluster_Manager

# Templates

- Create a virtual machine
- - You don't need CD drive
- - It's probably better to use q35 machine type
- - You don't need local disk
- - Look here for CPU types description: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_qemu_cpu_types
- Download a fresh cloud image
- - Debian: https://cloud.debian.org/images/cloud/
- - For example:
```bash
wget https://cloud.debian.org/images/cloud/bookworm/20230802-1460/debian-12-generic-amd64-20230802-1460.tar.xz
tar -xvf debian-12-generic-amd64-20230802-1460.tar.xz
```
- Install `virt-customize`: `apt install -y libguestfs-tools`
- Pre-install required tools into VM image
```bash
virt-customize -a disk.raw \
    --update \
    --install qemu-guest-agent \
    --install bash-completion,ncat,net-tools,iperf3,fio,curl,htop,dnsutils \
    --install ca-certificates,apt-transport-https,gnupg,ipvsadm,open-iscsi,nfs-common,cachefilesd \
    --uninstall unattended-upgrades \
    --run-command 'sudo rm /usr/sbin/shutdown && sudo tee /usr/sbin/shutdown << EOF && sudo chmod 755 /usr/sbin/shutdown
#!/bin/bash
exec systemctl poweroff
EOF' \
    --run-command 'sudo rm /usr/sbin/reboot && sudo tee /usr/sbin/reboot << EOF && sudo chmod 755 /usr/sbin/reboot
#!/bin/bash
exec systemctl reboot
EOF' \
    --truncate /etc/machine-id
```
- Add disk to VM
- - `qm disk import <vmid> <file> <storage-name>`
- - For example: `qm disk import 200 disk.raw local-zfs`
- Go to `VM Settings -> Hardware`
- - `Unused Disk 0`: add this disk to VM
- - - Resize added disk to size you need
- Go to `VM Settings -> Options -> Boot Order` and enable boot for the drive you added
- Add CloudInit Drive
- Go to `VM Settings -> CloudInit` and configure CloudInit

References:
- https://bugzilla.redhat.com/show_bug.cgi?id=1554546
- https://technotim.live/posts/cloud-init-cloud-image/
- https://www.reddit.com/r/Proxmox/comments/1058ko7/installing_tools_into_a_cloudinit_image/

# Ryzen 1000, 2000, 3000 setup

CPUs based on Zen, Zen+, Zen 2 architectures have a bug which makes them freeze when in the C6 state.

Previously there was a setting in BIOS that could fix it by disabling package C6 state.
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

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

- https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
- https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
- https://github.com/TheGrandWazoo/freenas-proxmox

# Perfect resource isolation

May be useful for gaming in VM.

References:
- https://forum.proxmox.com/threads/hey-proxmox-community-lets-talk-about-resources-isolation.124256/
