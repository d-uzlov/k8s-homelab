
# list all resources in a namespace
```bash
kl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl --kubeconfig=/mnt/a/var/ubuntu-k8s/kubeadm-master-config.yaml get --show-kind --ignore-not-found -n utorrent
```

# misc

show current mounts:
cat /proc/mounts

show open ports:
apt install net-tools
netstat -tuplen

# reset google chrome DNS cache

1. Open chrome dns page:
    chrome://net-internals/#dns
2. Press "Clear host cache".
3. Then close and re-launch chrome.

# Disable HSTS in chrome

Type `thisisunsafe` when the "Certificate error" page is open.

# Strange warning in pve console

Message from syslogd@pve at Mar 28 00:48:39 ...
 kernel:[2041562.177231] Uhhuh. NMI received for unknown reason 3d on CPU 11.

Message from syslogd@pve at Mar 28 00:48:39 ...
 kernel:[2041562.177234] Do you have a strange power saving mode enabled?

Message from syslogd@pve at Mar 28 00:48:39 ...
 kernel:[2041562.177235] Dazed and confused, but trying to continue

# Interesting program for system load monitoring

https://github.com/amanusk/s-tui

# LAN IP ranges

10.0.0.0/24 — static
10.0.1.0/24 — dhcp
10.0.2.0/24 — pve VMs
10.0.3.0/24 — k8s loadbalancer

# Reset DHCP in Windows

ipconfig /renew

# Find own IP

```bash
curl 'https://api.ipify.org'
```

# Kind: too many open files / inotify

Pod errors due to “too many open files”
This may be caused by running out of inotify resources. Resource limits are defined by fs.inotify.max_user_watches and fs.inotify.max_user_instances system variables. For example, in Ubuntu these default to 8192 and 128 respectively, which is not enough to create a cluster with many nodes.

To increase these limits temporarily run the following commands on the host:

```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

To make the changes persistent, edit the file /etc/sysctl.conf and add these lines:
```conf
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

fs.inotify.max_user_instances seems to be stuck at 128 after reboot.
Manual sysctl call fixes it until the next reboot.
At least this is what I see in the WSL 22.04.1 LTS 5.15.90.1-microsoft-standard-WSL2.
