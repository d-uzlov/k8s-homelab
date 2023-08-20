
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

# QEMU guest agent

Enable in `<vm-settings>` -> `Options` -> `QEMU Guest Agent`.

Install into VM:
```bash
# Debian / Ubuntu
sudo apt-get -y install qemu-guest-agent
sudo systemctl start qemu-guest-agent
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
cat <<EOF >> /etc/postfix/main.cf
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
```

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
- Add disk to VM
- - `qm disk import <vmid> <file> <storage-name>`
- - For example: `qm disk import 200 disk.raw local-zfs`
- Go to `VM Settings -> Hardware`
- - `Unused Disk 0`: add this disk to VM
- - - Resize added disk to size you need
- - Add CloudInit Drive
- Go to `VM Settings -> CloudInit` and configure CloudInit
- Go to `VM Settings -> Options -> Boot Order` and enable boot for the drive you added

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
https://github.com/TheGrandWazoo/freenas-proxmox
