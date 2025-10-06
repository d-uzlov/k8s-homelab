
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

# Memory hot (un)plug

Hot plug works without any special config.

Widely discussed possible performance issues likely don't exist,
unless you use several sockets.

Hot-unplug is broken, and proxmox wiki about it is severely outdated.

- `CONFIG_MOVABLE_NODE` parameter was removed in linux 4.13.
- `movable_node` kernel command line parameter will break VMs with a lot of memory,
because kernel internal structure can only live in unmovable memory,
and you can quickly run out of it, if almost all memory is movable.
- New way of dealing with it is `memory_hotplug.online_policy=auto-movable` kernel command line parameter.
It will work fine but proxmox will not handle it well. Kernel will mark low memory regions as movable,
but proxmox always tries to unplug high regions first.

Hot unplug can still work randomly without any additional configuration,
but only if you are lucky and required VM memory is empty.
You can't rely on it.

Older kernels usually set `CONFIG_MEMORY_HOTPLUG_DEFAULT_ONLINE=y`.
New kernels have a set of parameters, with default being `CONFIG_MHP_DEFAULT_ONLINE_TYPE_OFFLINE=y`.
This means that `/sys/devices/system/memory/auto_online_blocks` will be `offline` by default,
and kernel will not enable hot-plugged memory automatically.
You will need to add `memhp_default_state=online` to kernel parameters:

```bash

# edit GRUB_CMDLINE_LINUX_DEFAULT
sudo nano /etc/default/grub
sudo update-grub
sudo reboot

```

References:
- https://lore.proxmox.com/pve-user/4567346d-2a49-4989-9080-21a632113df3%40mattcorallo.com/T/
- https://docs.kernel.org/admin-guide/mm/memory-hotplug.html

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
