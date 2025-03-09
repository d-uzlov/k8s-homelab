
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

# Unique IDs

iSCSI and nvmeof require your nodes to have unique IDs.
IDs are generated on installation.
If you use VM templates, you may end up with duplicate IDs, which is bad.

Check IDs and correct them if needed:

```bash

# on current machine
cat /etc/nvme/hostid /etc/nvme/hostnqn /etc/iscsi/initiatorname.iscsi

# run on all k8s nodes
remotes=($(kl get node -o name | sed 's~node/~~'))
# or create bash array of hosts manually
remotes=
for host in "${remotes[@]}"; do
ssh $host cat /etc/nvme/hostid
done
for host in "${remotes[@]}"; do
ssh $host cat /etc/nvme/hostnqn
done
for host in "${remotes[@]}"; do
ssh $host cat /etc/iscsi/initiatorname.iscsi
done

```

Fixing IDs:

```bash

# replace example.com with your domain in reverse notation, date with current date
# this is required to generate globally-unique identifiers
# resulting VM IQN will be $iqn_prefix:$(hostname)
# refer to RFC3720 paragraph 3.2.6.3.1. for naming convention
#   http://www.faqs.org/rfcs/rfc3720.html
iqn_prefix=
# for example: iqn_prefix=iqn.2001-04.com.example:custom

# format for nqn is the same as iqn, except for the "nqn" prefix
# see paragraph 4.7 in NVMe Base Specification, Revision 2.1
#   https://nvmexpress.org/wp-content/uploads/NVM-Express-Base-Specification-Revision-2.1-2024.08.05-Ratified.pdf
nqn_prefix=
# for example: nqn_prefix=nqn.2001-04.com.example:custom

mkdir -p ./storage/democratic-csi-generic/env/
cat << EOF > ./storage/democratic-csi-generic/env/ids.env
iqn_prefix=$iqn_prefix
nqn_prefix=$nqn_prefix
EOF
. ./storage/democratic-csi-generic/env/ids.env

# run on all k8s nodes
remotes=($(kl get node -o name | sed 's~node/~~'))
# or create bash array of hosts manually
remotes=
for host in "${remotes[@]}"; do
ssh -T $host << generate-iqn-nqn-EOF
sudo chmod 644 /etc/iscsi/initiatorname.iscsi
echo InitiatorName=$iqn_prefix:\$(hostname) | sudo tee /etc/iscsi/initiatorname.iscsi
echo $nqn_prefix:\$(hostname) | sudo tee /etc/nvme/hostnqn
uuidgen | sudo tee /etc/nvme/hostid
touch ~/.hushlogin
generate-iqn-nqn-EOF
done

```
