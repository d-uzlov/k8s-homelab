
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

# Reset DNS cache in Google Chrome

1. Open chrome DNS page:
    `chrome://net-internals/#dns`
2. Press "Clear host cache".
3. Then close and re-launch chrome.

# Disable HSTS in chrome

Type `thisisunsafe` when the "Certificate error" page is open.

Beware that this completely disables checks for the whole domain.

Alternatively, delete site from HSTS list in [Chrome settings](chrome://net-internals/#hsts).

Not that this won't work if the site is in the preloaded HSTS list.

# Interesting program for system load monitoring

https://github.com/amanusk/s-tui

# Reset DHCP in Windows

```ps
ipconfig /renew
```

# Find own IP

```bash
curl 'https://api.ipify.org'
```
