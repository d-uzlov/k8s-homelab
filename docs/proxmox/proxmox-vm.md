
# Proxmox VM tips

This file contains some tips for configuring individual VMs in Proxmox.

# VM Secure boot

When using UEFI, secure boot is enabled by default.
It will prevent you from using custom kernels.

You can disable it in the BIOS screen, which opens if you press ESC during boot:

# QEMU guest agent

Enable in `<vm-settings> -> Options -> QEMU Guest Agent`.

Install into VM:

```bash
sudo apt-get -y install qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

# Disk performance

`virtio block` has better performance than `scsi` (aka `virtio scsi`)
but apparently each `virtio block` device consumes a pcie address,
which are apparently limited.
Also, `virtio block` doesn't support live disk resize.

SATA and IDE virtual drives should not be used unless you have compatibility concerns.

References:
- https://forum.proxmox.com/threads/virtio-vs-scsi.52893/

# Enable CPU hot-plug for Linux VMs

```bash
sudo tee /lib/udev/rules.d/80-hotplug-cpu.rules << EOF
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF

# not nessesary
# should fix issues if changes don't apply without reboot
sudo udevadm control --reload-rules && sudo udevadm trigger
```

In VM config set `sockets` and `cores` to maximum allowed values,
and then instead use `vCPUs` for real number of available cores.

References:
- [Proxmox documentation about Hot-Plug](https://pve.proxmox.com/wiki/Hotplug_(qemu_disk,nic,cpu,memory)#CPU_and_Memory_Hotplug)

# Templates

- Create a virtual machine
- - You don't need CD drive
- - It's probably better to use q35 machine type
- - You don't need local disk
- - Look here for CPU types description: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_qemu_cpu_types
- Download a fresh cloud image
- - Debian: https://cloud.debian.org/images/cloud/
- - For example:
```bash
wget https://cloud.debian.org/images/cloud/bookworm/20240211-1654/debian-12-generic-amd64-20240211-1654.tar.xz
tar -xvf debian-12-generic-amd64-20240211-1654.tar.xz
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
EOF' \
    --run-command 'sudo rm /usr/sbin/reboot && sudo tee /usr/sbin/reboot << EOF && sudo chmod 755 /usr/sbin/reboot
#!/bin/bash
exec systemctl reboot
EOF' \
    --run-command 'sudo tee /lib/udev/rules.d/80-hotplug-cpu.rules << EOF
SUBSYSTEM=="cpu", ACTION=="add", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
EOF' \
    --run-command 'sudo tee /etc/cloud/cloud.cfg.d/99_dnsfix.cfg << EOF
runcmd:
- '/usr/sbin/dhclient'
EOF' \
    --run-command 'sudo cloud-init clean' \
    --run-command 'sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s' \
    --truncate /etc/hostname \
    --truncate /etc/machine-id
```
- Add disk to VM
- - `qm disk import <vmid> <file> <storage-name>`
- - For example: `qm disk import 200 disk.raw local-zfs`
- Go to `VM Settings -> Hardware`
- - `Unused Disk 0`: add this disk to VM
- - - Resize added disk to size you need
- Go to `VM Settings -> Options -> Boot Order` and enable boot for the drive you added
- Add CloudInit Drive in Hardware settings
- Go to `VM Settings -> CloudInit` and configure CloudInit

References:
- https://bugzilla.redhat.com/show_bug.cgi?id=1554546
- https://technotim.live/posts/cloud-init-cloud-image/
- https://www.reddit.com/r/Proxmox/comments/1058ko7/installing_tools_into_a_cloudinit_image/

# Cloud-init DHCP hostname

Cloud-init expects to get the hostname via the network,
so it first initializes the network, then sets the hostname.

If you are using DHCP, DHCP will get the old hostname.
This is inconvenient, and may cause issues with automatic DNS.

```bash
# force cloud-init to renew the DHCP lease after hostname is updated
sudo tee /etc/cloud/cloud.cfg.d/99_dnsfix.cfg << EOF
runcmd:
- '/usr/sbin/dhclient'
EOF
```

References:
- https://forum.proxmox.com/threads/cloud-init-registering-dns-with-template-name.106726/
- https://bugs.launchpad.net/cloud-init/+bug/1739516

# Prepare existing VM to become a template

Just before the last shutdown of the VM clear all identifiers:

```bash
sudo cloud-init clean &&
sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s &&
echo | sudo tee /etc/hostname | sudo tee /etc/machine-id &&
sudo shutdown
```

# Perfect resource isolation

May be useful for gaming in VM.

References:
- https://forum.proxmox.com/threads/hey-proxmox-community-lets-talk-about-resources-isolation.124256/

# Fill memory

Can be useful to ensure that Proxmox doesn't unexpectedly kill a VM on OOM.

```bash
# will allocate 195 GiB
head -c 195G /dev/zero | tail
```
