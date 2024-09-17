
# Templates

- Create a virtual machine
- - Delete CD drive
- - It's probably better to use q35 machine type
- - Delete local disk
- - Look here for CPU types description: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_qemu_cpu_types
- Create and attach cloud image disk to VM
- - Download and [customize](#cloud-images) disk image
- - Attach resulting disk: `sudo qm disk import <vmid> <file> <storage-name>`
- - - For example: `sudo qm disk import 200 disk.raw local-zfs`
- Go to `VM Settings -> Hardware`
- - `Unused Disk 0`: enable this disk
- - Resize the new disk to size you need
- Go to `VM Settings -> Options -> Boot Order` and enable boot for the drive you added
- Add CloudInit Drive in Hardware settings
- Go to `VM Settings -> CloudInit` and configure CloudInit

References:
- https://bugzilla.redhat.com/show_bug.cgi?id=1554546
- https://technotim.live/posts/cloud-init-cloud-image/
- https://www.reddit.com/r/Proxmox/comments/1058ko7/installing_tools_into_a_cloudinit_image/

## Cloud images

## Cloud image: Debian

Check Debian cloud image archive for new versions:
- https://cloud.debian.org/images/cloud/

```bash
wget https://cloud.debian.org/images/cloud/bookworm/20240901-1857/debian-12-generic-amd64-20240901-1857.tar.xz
tar -xvf debian-12-generic-amd64-20240901-1857.tar.xz

```
- Install `virt-customize`: `sudo apt install -y libguestfs-tools`
- Pre-install required tools into VM image
```bash
sudo virt-customize -a disk.raw \
    --update \
    --install qemu-guest-agent \
    --install ca-certificates,apt-transport-https,gnupg,ipvsadm,open-iscsi,nfs-common,cachefilesd \
    --install bash-completion,ncat,net-tools,iperf3,fio,curl,htop,dnsutils,iotop,sysstat \
    --uninstall unattended-upgrades \
    --run-command 'sudo rm /usr/sbin/shutdown && sudo tee /usr/sbin/shutdown << EOF && sudo chmod 755 /usr/sbin/shutdown
#!/bin/bash
exec systemctl poweroff
EOF
'   --run-command 'sudo rm /usr/sbin/reboot && sudo tee /usr/sbin/reboot << EOF && sudo chmod 755 /usr/sbin/reboot
#!/bin/bash
exec systemctl reboot
EOF
'   --run-command 'sudo tee /lib/udev/rules.d/80-hotplug-cpu.rules << EOF
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF
'   --run-command 'sudo tee /etc/cloud/cloud.cfg.d/99_dnsfix.cfg << EOF
runcmd:
- /usr/sbin/dhclient
EOF
'   --run-command 'sudo tee /etc/sysctl.d/inotify.conf <<EOF
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
'   --run-command 'sudo tee /etc/sysctl.d/max_map_count.conf <<EOF
vm.max_map_count = 262144
EOF
'   --run-command 'sudo cloud-init clean && sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s' \
    --truncate /etc/hostname \
    --truncate /etc/machine-id
```
