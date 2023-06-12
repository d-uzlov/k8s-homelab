
# list all resources in a namespace

```bash
kl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl --kubeconfig=/mnt/a/var/ubuntu-k8s/kubeadm-master-config.yaml get --show-kind --ignore-not-found -n utorrent
```

# misc

```bash
show current mounts:
cat /proc/mounts

show open ports:
apt install net-tools
netstat -tuplen
```

# reset google chrome DNS cache

1. Open chrome dns page:
    chrome://net-internals/#dns
2. Press "Clear host cache".
3. Then close and re-launch chrome.

# Disable HSTS in chrome

Type `thisisunsafe` when the "Certificate error" page is open.

Beware that this completely disables checks for the whole domain.

Alternatively, delete site from HSTS list in [Chrome settings](chrome://net-internals/#hsts).

Not that this won't work if the site is in the preloaded HSTS list.

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

```ps
ipconfig /renew
```

# Find own IP

```bash
curl 'https://api.ipify.org'
```
