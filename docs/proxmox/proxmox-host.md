
# Proxmox host setup

This file contains some tips for configuring Proxmox host itself.

# Initial setup

Disable subscription warning:
```bash
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
```

Enable updates:
- `Datacenter / <node-name> / updates / repositories` -> add/enable/disable.
- Disable subscription-only repos
- - `https://enterprise.proxmox.com/debian/ceph-quincy`
- - `https://enterprise.proxmox.com/debian/pve`
- If it isn't already added by `pve-nag-buster`, add a subscription-free repo
- - `http://download.proxmox.com/debian/pve bullseye pve-no-subscription`
- - Reference: https://www.virtualizationhowto.com/2022/08/proxmox-update-no-subscription-repository-configuration/

Install useful tools:

```bash
apt install -y sudo
sudo apt install -y iperf3 htop
```

Add your user for SSH access: [SSH docs](../ssh.md).

**Note**: you can (and should) disable SSH password login
but don't disable root login, it is required by many proxmox functions.

# Config dir list

References:
- https://www.hungred.com/how-to/list-of-proxmox-important-configuration-files-directory/

# Network: custom MTU

```bash
# get max MTU of your device:
ip -d link | grep maxmtu -B 1
```

Set desired MTU in `<node-name> -> System -> Network / <device-name>`.

Don't forget to set network device MTU to 1 in VM hardware settings

# PCI-e passthrough

Summary:
- Edit kernel args using `sudo nano /etc/kernel/cmdline`
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

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

- https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
- https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
- https://github.com/TheGrandWazoo/freenas-proxmox
