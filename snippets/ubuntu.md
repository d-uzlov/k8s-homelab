
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

# после установки свежей ебунты

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -y install nfs-common

sudo apt -y autoremove

sudo apt install cachefilesd
sudo systemctl enable --now cachefilesd

# choose one:
sudo shutdown now
sudo reboot now
```

# Static IP

sudo nano etc/netplan/.......
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
# add these lines to /etc/sysctl.conf
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

In `WSL 22.04.1 LTS 5.15.90.1-microsoft-standard-WSL2`
fs.inotify.max_user_instances seems to be stuck at 128 after reboot.
Manual sysctl call fixes it until the next reboot.
