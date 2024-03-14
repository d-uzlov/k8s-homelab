
# Proxmox cluster setup

This file contains tips for configuring Proxmox cluster.

# Create cluster / join node

References:
- https://pve.proxmox.com/wiki/Cluster_Manager
- https://pve.proxmox.com/pve-docs/chapter-pvecm.html#pvecm_edit_corosync_conf

Prerequisites:
- !!! Make sure that your local node name resolves to your node IP address
- - `Datacenter -> Node name -> System -> Hosts`

Create / join:
- [if you don't have cluster yet] `Datacenter -> Cluster -> Create cluster` on one node
- If you have root password login disabled, enable it temporarily on the selected cluster node
- `Datacenter -> Cluster -> Create cluster` on a node in the cluster, copy join info
- `Datacenter -> Cluster -> Join cluster`, paste join info
- Input root password of the selected cluster node
- Wait a few minutes, web UI can be unavailable for some time while certificates are being re-generated

# Cluster diagnostics

```bash
sudo /usr/sbin/corosync-cfgtool -s

systemctl status corosync
sudo systemctl restart corosync
sudo journalctl -b -u corosync
# show logs between 2 dates
sudo journalctl -S '2024-03-15 17:35:18' -U '2024-03-15 17:35:21'

sudo pvecm status
```

# Updating corosync configuration

```bash
# edit current configuration
nano /etc/pve/corosync.conf
# config changes from /etc/pve/ should propagate to all nodes automatically
# provided you also bump config version field
# but you may need to do it on several nodes if sync doesn't work

# you may need to restart corosync to apply config changes
# you may need to do it on one affected node or on all nodes
systemctl restart corosync
systemctl status corosync
journalctl -b -u corosync
```

# Remove node

```bash
# Shows cluster names/list
ls -la /etc/pve/nodes/
# this one only shows active nodes
pvecm nodes
# Remove node
pvecm delnode NODE_NAME
rm -rf /etc/pve/nodes/NODE_NAME
```

# Force destroy cluster

```bash
sudo systemctl stop pve-cluster corosync &&
sudo pmxcfs -l &&
sudo rm -rf /etc/corosync/* &&
sudo rm -rf /etc/pve/corosync.conf &&
sudo killall pmxcfs &&
sudo systemctl start pve-cluster

# delete all ssh keys
sudo rm -f /root/.ssh/authorized_keys &&
sudo rm -f /etc/pve/priv/known_hosts &&
sudo rm -f /etc/ssh/ssh_known_hosts &&
sudo systemctl restart ssh.service &&
sudo systemctl restart sshd.service &&
sudo systemctl restart pve-cluster

# delete cached data about other nodes
sudo rm -rf /etc/pve/nodes/node-name/
```

References:
- https://pve.proxmox.com/wiki/Cluster_Manager

# Error: Host key verification failed

```bash
# this succeeds
/usr/bin/ssh -e none -o 'BatchMode=yes'                            root@node.ip /bin/true
# this fails
/usr/bin/ssh -e none -o 'BatchMode=yes' -o 'HostKeyAlias=nodename' root@node.ip /bin/true

# run this on the target node to fix
systemctl restart pveproxy
# for example
/usr/bin/ssh -e none -o 'BatchMode=yes' root@node.ip systemctl restart pveproxy
```
