
# ZFS

See here for ZFs installation instructions: [cockpit docs](../../../docs/cockpit/cockpit.md#zfs)

# SSH setup

Democratic CSI needs access to the following  commands:
- `zfs`
- `zpool`
- ¿ `chroot` ?

You either need to allow these commands,
or allow passwordless sudo, like this guide does.

User doesn't need to have password, you only need SSH access.

Generate SSH keys locally:

```bash

ssh-keygen -t ed25519 -C "democratic-csi" -N '' -f ./storage/democratic-csi-generic/proxy/env/ssh-key
ssh-keygen -b 4096 -f ./storage/democratic-csi-generic/proxy/env/ssh-key

# after you create user on the server,
# place contents of .pub file into ~/.ssh/authorized_keys
cat ./storage/democratic-csi-generic/proxy/env/ssh-key.pub

```

Run on the server to set up SSH access:

```bash

sudo useradd --create-home --shell /bin/bash democratic-csi
sudo adduser democratic-csi sudo

echo "democratic-csi ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/democratic-csi

sudo su - democratic-csi
mkdir -p ~/.ssh/
# paste ./storage/democratic-csi-generic/proxy/env/ssh-key.pub contents into authorized_keys
nano ~/.ssh/authorized_keys
touch ~/.hushlogin

```

# NVMEoF

```bash

sudo tee /etc/modules-load.d/nvmeof.conf << EOF
nvmet
nvmet-tcp
nvmet-rdma
EOF
sudo systemctl restart systemd-modules-load.service
lsmod | grep -e nvmet_tcp -e nvmet_rdma

sudo apt-get install -y git pip python3-six python3-pyparsing python3-configshell-fb

git clone --depth 1 git://git.infradead.org/users/hch/nvmetcli.git

( cd nvmetcli && sudo python3 setup.py install --prefix=/usr )
# .nvmetcli has excessive logs
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
