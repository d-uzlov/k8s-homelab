
# ZFS nas

This file roughyl describes what you should do
to create a NAS from empty Debian system using ZFS for file storage.

# Debian: install ZFS

```bash

. /etc/os-release
 sudo tee /etc/apt/sources.list.d/backports.list << EOF
deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main contrib
deb-src http://deb.debian.org/debian ${VERSION_CODENAME}-backports main contrib
EOF
 sudo tee /etc/apt/preferences.d/90-zfs << EOF
Package: src:zfs-linux
Pin: release n=${VERSION_CODENAME}-backports
Pin-Priority: 990
EOF

sudo apt update
apt-cache madison zfs-linux

sudo apt install -y dpkg-dev
# make sure that you have kernel headers, or ZFS will not be able to compile
# if you use custom kernel, you will need to get headers elsewhere
sudo apt install -y linux-headers-generic linux-image-generic
sudo apt install -y zfs-dkms zfsutils-linux

```

# maintenance

```bash

zpool list

pool_name=

# enable scrub once a month
sudo systemctl enable zfs-scrub-monthly@$pool_name.timer --now

# manual scrub
sudo zpool scrub $pool_name

# enable trim once a week
sudo systemctl enable zfs-trim-weekly@$pool_name.timer --now

# enable automatic trim after deletion
sudo zpool set autotrim=on $pool_name

# manual trim
sudo zpool trim $pool_name

```

# NVMEoF

```bash

sudo tee /etc/modules-load.d/nvmeof.conf << EOF
nvmet
nvmet-tcp
nvmet-rdma
EOF
sudo systemctl restart systemd-modules-load.service
lsmod | grep -e nvmet

sudo apt-get install -y git pip python3-six python3-pyparsing python3-configshell-fb

git clone --depth 1 git://git.infradead.org/users/hch/nvmetcli.git

( cd nvmetcli && sudo python3 setup.py install --prefix=/usr )
# .nvmetcli has excessive logs
sudo mkdir -p /root/.nvmetcli/
sudo ln -sf /dev/null /root/.nvmetcli/log.txt
# sudo ln -sf /dev/null /root/.nvmetcli/history.txt

sed -E 's|(ExecStart=.*)|\1\nExecStartPost=/usr/bin/touch /var/run/nvmet-config-loaded|' ./nvmetcli/nvmet.service | sudo tee /etc/systemd/system/nvmet.service
sudo mkdir -p /etc/nvmet
sudo systemctl daemon-reload
sudo systemctl enable --now nvmet.service
sudo systemctl status nvmet.service

# create a tcp port listening on all IPs on port 4420

 sudo nvmetcli << EOF
cd /ports
create 1
cd 1
set addr adrfam=ipv4 trtype=tcp traddr=0.0.0.0 trsvcid=4420
EOF
echo saveconfig /etc/nvmet/config.json | sudo nvmetcli

# interactive shell
sudo nvmetcli
# show local settings
sudo nvmetcli ls /

```

References:
- https://github.com/democratic-csi/democratic-csi?tab=readme-ov-file#zol-zfs-generic-nfs-zfs-generic-iscsi-zfs-generic-smb-zfs-generic-nvmeof

Additional info:
- https://www.linuxjournal.com/content/data-flash-part-iii-nvme-over-fabrics-using-tcp

# iSCSI

Server setup:

```bash

sudo apt-get install -y targetcli-fb

# interactive shell
sudo targetcli
# show local settings
sudo targetcli ls /

```

References:
- https://github.com/democratic-csi/democratic-csi?tab=readme-ov-file#zol-zfs-generic-nfs-zfs-generic-iscsi-zfs-generic-smb-zfs-generic-nvmeof

Additional info:
- https://kifarunix.com/how-to-install-and-configure-iscsi-storage-server-on-ubuntu-18-04/
- https://kifarunix.com/how-install-and-configure-iscsi-storage-server-on-centos-7/
- http://atodorov.org/blog/2015/04/07/how-to-configure-iscsi-target-on-red-hat-enterprise-linux-7/

# NFS

```bash

sudo apt install -y nfs-kernel-server

# list exports
sudo showmount -e
# show config files
sudo cat /etc/exports
ls /etc/exports.d/*
sudo cat /etc/exports.d/*

```

Additional info:
- https://docs.oracle.com/cd/E23824_01/html/821-1448/gayne.html

# Samba / SMB

See samba docs: [samba.md](../../../docs/samba.md).
