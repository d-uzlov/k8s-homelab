
# Change node IP

References:
- https://bookstack.dismyserver.net/books/documentation/page/how-to-change-the-ip-address-of-a-proxmox-clustered-node
- https://forum.proxmox.com/threads/change-cluster-nodes-ip-addresses.33406/
- https://pve.proxmox.com/wiki/Cluster_Manager#_remove_a_cluster_node

```bash
# Stop the cluster services
sudo systemctl stop pve-cluster
sudo systemctl stop corosync

# Mount the filesystem locally
sudo pmxcfs -l

# Edit the network interfaces file to have the new IP information
# Be sure to replace both the address and gateway
sudo nano /etc/network/interfaces

# Replace any host entries with the new IP addresses
sudo nano /etc/hosts

# Change the DNS server as necessary
sudo nano /etc/resolv.conf

# Edit the corosync file and replace the old IPs with the new IPs for all hosts
# :%s/192\.168\.1\./192.168.2./g   <- vi command to replace all instances
# BE SURE TO INCREMENT THE config_version: x LINE BY ONE TO ENSURE THE CONFIG IS NOT OVERWRITTEN
sudo nano /etc/pve/corosync.conf

# Edit the known hosts file to have the correct IPs
# :%s/192\.168\.1\./192.168.2./g   <- vi command to replace all instances
sudo nano /etc/pve/priv/known_hosts

# If using ceph, edit the ceph configuration file to reflect the new network
# (thanks u/FortunatelyLethal)
# :%s/192\.168\.1\./192.168.2./g   <- vi command to replace all instances
sudo nano /etc/ceph/ceph.conf

# If you want to be granular... fix the IP in /etc/issue
sudo nano /etc/issue

# Verify there aren't any stragglers with the old IP hanging around
cd /etc
grep -R '192\.168\.1\.' *
cd /var
grep -R '192\.168\.1\.' *

# Reboot the system to cleanly restart all the networking and services
reboot
```

# Custom MTU

```bash
# get max MTU of your device:
ip -d link | grep maxmtu -B 1
```

Set desired MTU in `<node-name> -> System -> Network / <device-name>`.

Don't forget to set network device MTU to 1 in VM hardware settings.

```bash
# check if your desired MTU is currently allowed in the network
ping -M do -i 0.002 -c 1 -s $((9198 - 28)) 10.0.0.2

# you can set MTU manually for testing
sudo ip link set dev ln_storage mtu 9200
```

# LACP status

```bash
cat /proc/net/bonding/bond0
```

# Mellanox ConnectX-3 VLANs

Mellanox ConnectX-3 only supports 126 VLANs.

If you set "VLAN aware" on a bridge in proxmox, proxmox will try to enable VLANs 2-4094,
which is a lot more than 126.
You will see an error like this:

```bash
failed to set vid `{ 127, 128 ... 4093, 4094}`
cmd '/sbin/bridge -force -batch - [vlan add vid 127-4094 dev enp65s0 ]'
failed: No space left on device
```

There are several workarounds:

- Limit VLANs to 2-126
- - Edit bridge in /etc/network/interfaces
```bash
auto vmbr0
iface vmbr0 inet static
  ...
  bridge-vlan-aware yes
  bridge-vids 2-126
```
- Set VLANs you need manually, instead of using a long list
- - Edit bridge in /etc/network/interfaces
```bash
auto vmbr0
iface vmbr0 inet static
  ...
  bridge-vlan-aware yes
  bridge-vids 2 10 50 228 1999
```
- Don't use VLAN aware bridges
- - You can create a separate bridge for a specific VLAN
- - Technically this is similar to defining VLANs you need manually
- - When using Proxmox SDN it already creates special bridges, so just don't set VLAN aware checkbox
- Disable VLAN hardware offloading
- - This may or may not work depending on driver capabilities
- - Edit physical interface in /etc/network/interfaces
```bash
iface enp129s0 inet manual
  rx-vlan-filter off
```

Note that when using VLAN aware bridges VM guests
will receive traffic from all VLANs
which can be a security issue,
and you probably don't want it for most of your VMs.

As mentioned earlier, you can still use VLAN traffic
when using a separate VLAN interface, even without VLAN aware bridge.

References:
- https://forum.proxmox.com/threads/vlan-with-tag-above-126-problem.46072/page-2
- https://forum.proxmox.com/threads/vlan-issues.124714/
- https://www.reddit.com/r/homelab/comments/114ieep/proxmox_bridgevids_option_host_itself_in_vlan/
