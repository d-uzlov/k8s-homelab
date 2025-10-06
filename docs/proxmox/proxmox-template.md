
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
- https://cloud.debian.org/images/cloud/trixie/

```bash

# this is just an arbitrary version at the time of writing this
# this is periodically updated
version=20250924-2245
wget https://cloud.debian.org/images/cloud/trixie/$version/debian-13-generic-amd64-$version.tar.xz

# tar will produce disk.raw in ./debian-13-generic-amd64-$version
rm -rf ./debian-13-generic-amd64-$version
mkdir -p ./debian-13-generic-amd64-$version
tar --verbose --extract --directory ./debian-13-generic-amd64-$version --file debian-13-generic-amd64-$version.tar.xz

```

## Cloud image: customize

```bash

cd ./debian-13-generic-amd64-$version

# install system tools
virt-customize -a disk.raw --update --install qemu-guest-agent,ca-certificates,apt-transport-https,gnupg,lsb-release,open-iscsi,nfs-common,cachefilesd,samba,nvme-cli,lsscsi
# install user tools
virt-customize -a disk.raw --update --install bash-completion,ncat,net-tools,iperf3,fio,curl,htop,dnsutils,iotop,sysstat,git,make

virt-customize -a disk.raw \
  --copy-in ~/cloud-scripts/udev/80-hotplug-cpu.rules:/lib/udev/rules.d/ \
  --mkdir /opt/scripts/ \
  --copy-in ~/cloud-scripts/scripts/boot-cmd.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/image-cleanup.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/init-user-skel.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/sysctl/inotify.conf:/etc/sysctl.d/ \
  --copy-in ~/cloud-scripts/sysctl/max_map_count.conf:/etc/sysctl.d/ \
  --copy-in ~/cloud-scripts/logind/unattended-upgrades-logind-maxdelay.conf:/usr/lib/systemd/logind.conf.d/ \
  --copy-in ~/cloud-scripts/cloud-systemd/cloud-boot.service:/etc/systemd/system/ \
  --run-command 'sudo systemctl enable cloud-boot.service' \
  --run ~/cloud-scripts/init-user-skel.sh

# clean files created during customization
virt-customize -a disk.raw --run ~/cloud-scripts/image-cleanup.sh --truncate /etc/hostname --truncate /etc/machine-id

```

# modify existing VM without booting it

Make sure VM is not running when you do this.

```bash

# look up disk name in VM hardware settings in proxmox web-ui
disk_name=vm-206-disk-1

sudo virt-customize -a /dev/zvol/rpool/data/$disk_name \
  --copy-in ~/cloud-scripts/udev/80-hotplug-cpu.rules:/lib/udev/rules.d/ \
  --mkdir /opt/scripts/ \
  --copy-in ~/cloud-scripts/scripts/boot-cmd.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/image-cleanup.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/init-user-skel.sh:/opt/scripts/ \
  --copy-in ~/cloud-scripts/sysctl/inotify.conf:/etc/sysctl.d/ \
  --copy-in ~/cloud-scripts/sysctl/max_map_count.conf:/etc/sysctl.d/ \
  --copy-in ~/cloud-scripts/logind/unattended-upgrades-logind-maxdelay.conf:/usr/lib/systemd/logind.conf.d/ \
  --copy-in ~/cloud-scripts/cloud-systemd/cloud-boot.service:/etc/systemd/system/ \
  --run-command 'sudo systemctl enable cloud-boot.service' \
  --run ~/cloud-scripts/init-user-skel.sh

```

# cloud-init debug

```bash

# check config file syntax (should work anywhere)
cloud-init schema --config-file /path/to/file

# check logs (in the VM)
cat /var/log/cloud-init-output.log
cat /var/log/cloud-init.log

# check current values provided from host
sudo cloud-init query userdata

# check config syntax
cloud-init schema --system

# show stages
cloud-init analyze show

```

There is no way to show full config as cloud-init sees it.
