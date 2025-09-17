
# virt-customize

# Install

```bash

sudo apt install -y libguestfs-tools
sudo usermod -aG kvm $USER
newgrp kvm

```

# Helper files

```bash

rm -r ~/cloud-scripts/
mkdir -p ~/cloud-scripts/
mkdir -p ~/cloud-scripts/udev/
mkdir -p ~/cloud-scripts/scripts/
mkdir -p ~/cloud-scripts/sysctl/
mkdir -p ~/cloud-scripts/sbin/
mkdir -p ~/cloud-scripts/logind/
mkdir -p ~/cloud-scripts/cloud-systemd/

# enable CPU hot plug
 cat << EOF > ~/cloud-scripts/udev/80-hotplug-cpu.rules
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF

 cat << "boot-cmd-EOF" > ~/cloud-scripts/scripts/boot-cmd.sh
#!/bin/bash
set -eux

echo check /run/test-init.log for cloud-init boot-cmd logs
exec >> /run/test-init.log 2>&1

echo renewing DHCP lease...
# dhcp name is outdated on the first boot
# /usr/sbin/dhclient
systemctl restart systemd-networkd.service

echo generating iscsi name...
tee /etc/iscsi/initiatorname.iscsi << initiatorname.iscsi-EOF
InitiatorName=iqn_prefix:$(hostname)
initiatorname.iscsi-EOF

echo generating nvme name...
tee /etc/nvme/hostnqn << hostnqn-EOF
nqn_prefix:$(hostname)
hostnqn-EOF
# hostid should only be generated if it is missing
[ -f /etc/nvme/hostid ] && [ $(wc -c < /etc/nvme/hostid) = 37 ] || uuidgen | sudo tee /etc/nvme/hostid
boot-cmd-EOF

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

sed -i -e "s/iqn_prefix/$iqn_prefix/" -e "s/nqn_prefix/$nqn_prefix/" ~/cloud-scripts/scripts/boot-cmd.sh

chmod +x ~/cloud-scripts/scripts/boot-cmd.sh

 cat << EOF > ~/cloud-scripts/sysctl/inotify.conf
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 65536
EOF

 cat << EOF > ~/cloud-scripts/sysctl/max_map_count.conf
vm.max_map_count = 262144
EOF

 cat << EOF > ~/cloud-scripts/logind/unattended-upgrades-logind-maxdelay.conf
[Login]
# delay
InhibitDelayMaxSec=60
EOF

# https://www.reddit.com/r/Proxmox/comments/plct2v/are_there_any_current_guides_on_templatingcloning/
 cat << "image-cleanup-EOF" > ~/cloud-scripts/image-cleanup.sh
#!/bin/bash
set -eu

apt-get clean
apt-get autoremove
cloud-init clean

rm /etc/iscsi/initiatorname.iscsi
rm /etc/nvme/hostnqn
rm /etc/nvme/hostid

# replace log files with empty ones, to avoid errors when something expects log file to exist
for CLEAN in $(find /var/log/ -type f)
do
  cp /dev/null $CLEAN
done
rm -rf /var/log/journal/*

rm -rf /tmp/*
rm -rf /var/tmp/*
image-cleanup-EOF

chmod +x ~/cloud-scripts/image-cleanup.sh

curl https://raw.githubusercontent.com/d-uzlov/k8s-homelab/refs/heads/master/docs/bash-setup.md | sed -n '/```bash/,/```/{//!p;}' | sed '1i\export HOME=/etc/skel' > ~/cloud-scripts/init-user-skel.sh

 cat << EOF > ~/cloud-scripts/cloud-systemd/cloud-boot.service
[Unit]
Description=Cloud-init post-boot
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/scripts/boot-cmd.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

```
