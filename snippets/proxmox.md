
в proxmox:
включить обновления:
<node name> -> updates -> repositories -> add/enable/disable
убрать subscription warning:
curl https://raw.githubusercontent.com/foundObjects/pve-nag-buster/master/install.sh | bash
узнать maxmtu:
ip -d link | grep maxmtu -B 1
поставить временно:
ip link set enxf8e43bd6ac4c mtu 4088
поставить постоянно:
изменить /etc/network/interfaces, добавить строку "mtu 1111"
например:
iface enxf8e43bd6ac4c inet manual
        mtu 4088
в настройках адаптера ВМки поставить MTU=1 (наследовать от свича)
параметры ядра:
отредактировать:
nano /etc/kernel/cmdline
Сохранить изменения:
proxmox-boot-tool refresh
перезагрузиться
Параметр для полноценного pci passthrough:
pcie_acs_override=downstream,multifunction
Но обращаться с ним надо осторожно, т.к. он, по сути, отключает проверки безопасности
Существует он только потому, что долбоебы делают оборудование,
которое должно бы отвечать на проверки безопасности, но не отвечает

настроить уведомления:
https://gist.github.com/tomdaley92/9315b9326d4589c9652ce0307c9c38a3
postconf -e "inet_protocols = ipv4"
гугл работает, яндекс не работает

# iscsi + CHAP

https://www.wundertech.net/how-to-set-up-iscsi-storage-on-proxmox/

# zfs over iscsi

https://forum.proxmox.com/threads/proxmox-ve-and-zfs-over-iscsi-on-truenas-scale-my-steps-to-make-it-work.125387/
https://xinux.net/index.php/Proxmox_iscsi_over_zfs_with_freenas
https://github.com/TheGrandWazoo/freenas-proxmox
