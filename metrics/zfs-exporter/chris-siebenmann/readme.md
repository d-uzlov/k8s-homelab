
# ZFS exporter outside of k8s cluster

# Prerequisites

- [Golang](../../../docs/golang.md#install)

# Linux installation

References:
- https://github.com/siebenmann/zfs_exporter

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
  -depth=2 \
  -fullpath \
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

# adjust cluster_type and cluster to your needs
# if scrape-patch.yaml already exists, add more items into staticConfigs list
 cat << EOF > ./metrics/zfs-exporter/chris-siebenmann/env/scrape-patch.yaml
 ---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-zfs-exporter-chris
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      job: zfs-exporter
      cluster_type: pve
      cluster: cluster-name
    targets:
    - node1.example.com:9700
    - node2.example.com:9700
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
node=nas-tulip.storage.lan
curl -sS --insecure http://$node:9700/metrics > ./zfs-exporter-chris.log

```
