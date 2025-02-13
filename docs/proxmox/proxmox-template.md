
# Templates

Prerequisites:
- [virt-customize](./virt-customize.md) with helper config files

- Create a virtual machine
- - Disable CD drive
- - It's probably better to use q35 machine type
- - Select `OVMF (UEFI)`, disable `Pre-Enroll keys`
- - Enable `QEMU Agent`
- - Delete local disk
- - Look here for CPU types description: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_qemu_cpu_types
- Create and attach cloud image disk to VM
- - [Download](#cloud-images) disk image
- - [Customize](#cloud-image-customize) disk image
- - Attach resulting disk: `sudo qm disk import <vmid> <file> <storage-name>`
- - - For example: `sudo qm disk import 200 disk.raw local-zfs`
- `VM Settings -> Hardware`
- - `Unused Disk 0`: enable this disk
- - Resize the new disk to size you need
- - Delete CD Drive
- - Add CloudInit Drive
- - [optional] Add Serial Port and change Display from Default to Serial
- `VM Settings -> Options -> Boot Order`: enable boot for the drive you added
- `VM Settings -> CloudInit`: configure CloudInit

References:
- https://bugzilla.redhat.com/show_bug.cgi?id=1554546
- https://technotim.live/posts/cloud-init-cloud-image/
- https://www.reddit.com/r/Proxmox/comments/1058ko7/installing_tools_into_a_cloudinit_image/

## Cloud images

## Cloud image: Debian

Check Debian cloud image archive for new versions:
- https://cloud.debian.org/images/cloud/

```bash
# this is just an arbitrary version at the time of writing this
# this is periodically updated
version=20250115-1993
wget https://cloud.debian.org/images/cloud/bookworm/$version/debian-12-generic-amd64-$version.tar.xz
# tar will produce disk.raw in the current directory
tar -xvf debian-12-generic-amd64-$version.tar.xz
```

## Cloud image: customize

```bash
# install system tools
virt-customize -a disk.raw --update --install qemu-guest-agent,ca-certificates,apt-transport-https,gnupg,lsb-release,open-iscsi,nfs-common,cachefilesd,samba,nvme-cli
# install user tools
virt-customize -a disk.raw --update --install bash-completion,ncat,net-tools,iperf3,fio,curl,htop,dnsutils,iotop,sysstat,git,make

virt-customize -a disk.raw \
  --copy-in ~/cloud-scripts/udev/:/lib/udev/rules.d/ \
  --copy-in ~/cloud-scripts/cloud-init-cfg/:/etc/cloud/cloud.cfg.d/ \
  --copy-in ~/cloud-scripts/scripts/:/opt/scripts/ \
  --copy-in ~/cloud-scripts/sysctl/:/etc/sysctl.d/ \
  --delete /usr/sbin/shutdown \
  --delete /usr/sbin/reboot \
  --delete /etc/iscsi/initiatorname.iscsi \
  --delete /etc/nvme/hostnqn \
  --delete /etc/nvme/hostid \
  --copy-in ~/cloud-scripts/sbin/:/usr/sbin/ \
  --copy-in ~/cloud-scripts/logind/:/usr/lib/systemd/logind.conf.d

# https://www.reddit.com/r/Proxmox/comments/plct2v/are_there_any_current_guides_on_templatingcloning/
 cat << "image-cleanup-EOF" > ~/cloud-scripts/image-cleanup.sh
#!/bin/bash
set -eu

apt-get clean
apt-get autoremove
cloud-init clean

# replace log files with empty ones, to avoid errors when something expects log file to exist
for CLEAN in $(find /var/log/ -type f)
do
  cp /dev/null  $CLEAN
done
rm -rf /var/log/journal/*

rm -rf /tmp/*
rm -rf /var/tmp/*
image-cleanup-EOF

# clean files created during customization
virt-customize -a disk.raw --run ~/cloud-scripts/image-cleanup.sh --truncate /etc/hostname --truncate /etc/machine-id

```

# Check cloud-init logs

```bash
cat /var/log/cloud-init-output.log
```
