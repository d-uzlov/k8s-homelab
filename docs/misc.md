
# list all resources in a namespace

```bash
# set to your calue
namespace=cilium
kl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl --kubeconfig $KUBECONFIGLOCAL get --show-kind --ignore-not-found -n $namespace
```

# Show current mounts

```bash
cat /proc/mounts
```

# Show open ports

```bash
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
echo $(curl -sS https://api.ipify.org)
```

# mount NFS

```bash
sudo mkdir /mnt/bulk
sudo mount -t nfs truenas.lan:/mnt/main/prox/nn /mnt/bulk
```
