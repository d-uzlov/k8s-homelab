
# Initial setup

Enable updates: `<node-name>` -> `updates` -> `repositories` -> `add/enable/disable`.

Disable subscription warning:
```bash
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
```

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

```bash
# Edit kernel args
nano /etc/kernel/cmdline
# After editing
# (assuming you installed proxmox on ZFS)
proxmox-boot-tool refresh
reboot

# kernel arg for pci passthrough force
pcie_acs_override=downstream,multifunction
# be careful, this disables most of the security checks
# because consumer hardware doesn't support security
# because of stupid corporations
```

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
sudo tee /lib/udev/rules.d/80-hotplug-cpu.rules <<EOF
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF

# not nessesary
# should fix issues if changes don't apply without reboot
sudo udevadm control --reload-rules && sudo udevadm trigger
```

References:
- [Proxmox documentation in Hot-Plug](https://pve.proxmox.com/wiki/Hotplug_(qemu_disk,nic,cpu,memory)#CPU_and_Memory_Hotplug)

# TODO

iscsi + CHAP:

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

zfs over iscsi:

https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
https://github.com/TheGrandWazoo/freenas-proxmox
