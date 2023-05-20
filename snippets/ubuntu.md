
# в ubuntu-k8s:

при первом запуске нажать ESC во время загрузки BIOS/EFI
Перейти в настройки secure boot и снять крестик. Сохраниться, перезагрузиться.
при установке не забыть расширить партишн до максимума

# Fix 'too many open files' issue

```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

# To make the changes persistent, edit the file /etc/sysctl.conf and add these lines:

fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

fs.inotify.max_user_instances seems to be stuck at 128 after reboot.
Manual sysctl call fixes it until the next reboot.
At least this is what I see in the WSL 22.04.1 LTS 5.15.90.1-microsoft-standard-WSL2.

# после установки свежей ебунты

```bash
sudo apt-get update
sudo apt-get -y install qemu-guest-agent
sudo systemctl start qemu-guest-agent
sudo apt-get upgrade -y

sudo apt-get -y install nfs-common

sudo apt -y autoremove

# for calico (if network manager is installed)
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

sudo apt install cachefilesd
sudo systemctl enable --now cachefilesd

# choose one:
sudo shutdown now
sudo reboot now
```

# конфигурациz статического ip в ебунте:
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

# extend LVM

```bash
sudo vgdisplay
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```
