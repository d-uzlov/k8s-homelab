
# CLient setup for generic-zfs drivers

# NVMEoF

```bash

sudo apt-get install -y nvme-cli

# list connections
sudo nvme list-subsys

```

# iSCSI

```bash

sudo apt-get -y install open-iscsi

# print detailed info about sessions
sudo iscsiadm --mode session -P 3
# disconnect session
sudo iscsiadm -m node -T share_iqn -p address:port -u

```

# NFS

```bash

sudo apt install -y nfs-common

```

# Samba / SMB

```bash

sudo apt install -y smbclient
sudo apt install cifs-utils

```

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
