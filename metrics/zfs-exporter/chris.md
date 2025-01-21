
```bash
git clone --depth 1 -b cks-upstream https://github.com/siebenmann/zfs_exporter.git
cd zfs_exporter/
CGO_ENABLED=0 go build -ldflags="-w -s" -o zfs-exporter-chris main.go
```

# Manual metric checking

```bash
# ip or domain name
node=tyan.proxmox.wrq.duckdns.org
curl -sS --insecure http://$node:9700/metrics > ./zfs-exporter-chris.log
```
