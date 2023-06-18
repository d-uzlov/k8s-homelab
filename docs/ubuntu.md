
# When installing

Don't forget to increase LVM partition size to 100%.
при установке не забыть расширить партишн до максимума

# extend LVM

If you forgot to increase LVM size during installation,
you can do it manually afterwards:

```bash
sudo vgdisplay
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```

# Ubuntu initial setup

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -y install nfs-common
sudo apt-get -y install fio
sudo apt-get -y remove unattended-upgrades

sudo apt -y autoremove

sudo apt install cachefilesd
sudo systemctl enable --now cachefilesd

sudo tee /usr/sbin/shutdown <<EOF
#!/bin/bash
exec systemctl poweroff
EOF
sudo tee /usr/sbin/reboot <<EOF
#!/bin/bash
exec systemctl reboot
EOF

# choose one:
sudo shutdown now
sudo reboot now
```

# Network manager

```bash
# if you want to use it:
sudo mkdir -p /etc/NetworkManager/conf.d/
sudo tee /etc/NetworkManager/conf.d/calico.conf <<EOF
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
EOF

# Stop network manager
sudo systemctl stop NetworkManager.service
sudo systemctl stop NetworkManager-wait-online.service
sudo systemctl stop NetworkManager-dispatcher.service
sudo systemctl stop network-manager.service
# Disable network manager (permanently) to avoid it restarting after a reboot
sudo systemctl disable NetworkManager.service
sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable NetworkManager-dispatcher.service
sudo systemctl disable network-manager.service
```

# Change hostname

```bash
sudo hostnamectl set-hostname km1
# optionally you can also update hosts
sudo nano /etc/hosts
```

# Static IP

sudo nano /etc/netplan/00-installer-config.yaml
```yaml
network:
  ethernets:
    ens18:
      addresses:
      - 10.0.2.103/16
      nameservers:
        addresses:
        - 10.0.0.1
        search:
        - example
      routes:
      - to: default
        via: 10.0.0.1
    ens19:
      addresses:
      - 192.168.10.103/24
  version: 2
```

# Fix 'too many open files' issue

In Ubuntu default values are 8192 and 128 respectively.

```bash
# change limits for current session
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

# change permanently
# make sure that /etc/sysctl.conf
# or other files in /etc/sysctl.d/
# don't override these values
sudo tee /etc/sysctl.d/inotify.conf <<EOF
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
```

In `WSL 22.04.1 LTS 5.15.90.1-microsoft-standard-WSL2`
`fs.inotify.max_user_instances` seems to be stuck at 128 after reboot.
Manual `sysctl` call fixes it until the next reboot.

# TRIM

```bash
sudo fstrim -v /
```

# Print full system config

```bash
sudo sysctl --system
```

# benchmark disk writes

```bash
fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
```
