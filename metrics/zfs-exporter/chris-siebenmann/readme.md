
# ZFS exporter outside of k8s cluster

# Prerequisites

- [Golang](../../docs/golang.md#install)

# Linux installation

References:
- https://github.com/pdf/zfs_exporter

Run on the target system:

```bash

git clone --depth 1 -b cks-upstream https://github.com/siebenmann/zfs_exporter.git
( cd zfs_exporter/; CGO_ENABLED=0 go build -ldflags="-w -s" -o zfs-exporter-chris main.go )

sudo groupadd --system zfs_exporter_chris
sudo useradd -s /sbin/nologin --system -g zfs_exporter_chris zfs_exporter_chris

 sudo tee /etc/systemd/system/zfs_exporter_chris.service << EOF
[Unit]
Description=ZFS Exporter by Chris Siebenmann
Wants=network-online.target
After=network-online.target

[Service]
User=zfs_exporter_chris
ExecStart=$(which ~/zfs_exporter/zfs-exporter-chris) \
  -listen-addr=:9700

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart zfs_exporter_chris
sudo systemctl enable zfs_exporter_chris
systemctl status --no-pager zfs_exporter_chris.service
sudo journalctl -b -u zfs_exporter_chris

```

# Prometheus scrape config

```bash
mkdir -p ./metrics/zfs-exporter/chris-siebenmann/env/

[ -f ./metrics/zfs-exporter/chris-siebenmann/env/targets-patch.yaml ] ||
  cp ./metrics/zfs-exporter/chris-siebenmann/scrape-patch.template.yaml ./metrics/zfs-exporter/chris-siebenmann/env/scrape-patch.yaml

# adjust cluster_type and cluster to your needs
# repeat if you need to scrape several clusters with different names
 cat << EOF >> ./metrics/zfs-exporter/chris-siebenmann/env/scrape-patch.yaml
  - labels:
      job: zfs-exporter
      cluster_type: pve
      cluster: cluster-name
    targets:
    - node1.example.com:9700
    - node2.example.com:9700
    - node3.example.com:9700
EOF

kl apply -k ./metrics/zfs-exporter/chris-siebenmann/
kl -n prometheus describe scrapeconfig external-zfs-exporter-chris

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/chris-siebenmann/
```

# Manual metric checking

```bash
# ip or domain name
node=
curl -sS --insecure http://$node:9700/metrics > ./zfs-exporter-chris.log
```
