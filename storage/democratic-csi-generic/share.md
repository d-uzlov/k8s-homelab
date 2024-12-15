
# Shares

This file describes server setup that is required
to use it for shares when using
democratic-csi with `zfs-generic-*` drivers.

Before anything, you need to get ZFS.
ZFS installation isn't covered here.

# User

Democratic CSI needs access to the following  commands:
- `zfs`
- `zpool`
- ¿ `chroot` ?

You either need to allow these commands,
or allow passwordless sudo.

User doesn't need to have password, you only need SSH access.

```bash
# run on the server
sudo useradd --create-home --shell /bin/bash democratic-csi
sudo adduser democratic-csi sudo

echo "democratic-csi ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/democratic-csi

# run on the client
ssh-keygen -t ed25519 -C "democratic-csi" -N '' -f ./storage/democratic-csi-generic/proxy/env/ssh-key-2
ssh-keygen -b 4096 -f ./storage/democratic-csi-generic/proxy/env/ssh-key

# copy ssh-key.pub into the authorized_keys on the server
cat ./storage/democratic-csi-generic/proxy/env/ssh-key.pub

# run on the server
sudo su - democratic-csi
mkdir -p ~/.ssh/
nano ~/.ssh/authorized_keys
# disable motd
touch ~/.hushlogin

# test SSH access from the client
server=
ssh -i ./storage/democratic-csi-generic/proxy/env/ssh-key democratic-csi@$server
```

# NVMEoF

Server setup:

```bash
sudo tee /etc/modules-load.d/nvmeof.conf << EOF
nvmet
nvmet-tcp
nvmet-rdma
EOF
sudo systemctl restart systemd-modules-load.service

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

Client setup:

```bash
sudo apt-get install -y nvme-cli

# list connections
sudo nvme list-subsys
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

Client setup:

```bash
sudo apt-get -y install open-iscsi

# print detailed info about sessions
sudo iscsiadm --mode session -P 3
# disconnect session
sudo iscsiadm -m node -T share_iqn -p address:port -u
```

References:
- https://github.com/democratic-csi/democratic-csi?tab=readme-ov-file#zol-zfs-generic-nfs-zfs-generic-iscsi-zfs-generic-smb-zfs-generic-nvmeof

Additional info:
- https://kifarunix.com/how-to-install-and-configure-iscsi-storage-server-on-ubuntu-18-04/
- https://kifarunix.com/how-install-and-configure-iscsi-storage-server-on-centos-7/
- http://atodorov.org/blog/2015/04/07/how-to-configure-iscsi-target-on-red-hat-enterprise-linux-7/

# NFS

Server setup:

```bash
sudo apt install -y nfs-kernel-server

# list exports
sudo showmount -e
# show config files
sudo cat /etc/exports /etc/exports.d/*
```

Client setup:

```bash
sudo apt install -y nfs-common
```

Additional info:
- https://docs.oracle.com/cd/E23824_01/html/821-1448/gayne.html

# Samba / SMB

Server setup:

```bash
sudo apt install -y samba

# show shares
sudo net usershare info --long
sudo ls -la /var/lib/samba/usershares/
# show currently connected sessions
sudo smbstatus
# print raw share config
cat /etc/samba/smb.conf
cat /etc/samba/smb.conf | grep include
```

Client setup:

```bash
sudo apt install -y smbclient
sudo apt install cifs-utils
```

Additional info:
- https://docs.oracle.com/cd/E23824_01/html/821-1448/gayne.html
