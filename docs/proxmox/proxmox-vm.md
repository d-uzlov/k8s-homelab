
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

# not necessary
# should fix issues if changes don't apply without reboot
sudo udevadm control --reload-rules && sudo udevadm trigger
```

In VM config set `sockets` and `cores` to maximum allowed values,
and then instead use `vCPUs` for real number of available cores.

References:
- [Proxmox documentation about Hot-Plug](https://pve.proxmox.com/wiki/Hotplug_(qemu_disk,nic,cpu,memory)#CPU_and_Memory_Hotplug)

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
