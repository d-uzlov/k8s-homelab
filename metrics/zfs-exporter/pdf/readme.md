
# ZFS exporter outside of k8s cluster

# Prerequisites

- [Golang](../../docs/golang.md#install)

# Linux installation

References:
- https://github.com/pdf/zfs_exporter

Run on the target system:

```bash

sudo apt-get update
sudo apt-get install -y git

# https://github.com/pdf/zfs_exporter/releases
zfs_exporter_version=v2.3.6
go install github.com/pdf/zfs_exporter/v2@$zfs_exporter_version

sudo groupadd --system zfs_exporter
sudo useradd -s /sbin/nologin --system -g zfs_exporter zfs_exporter

 sudo tee /etc/systemd/system/zfs_exporter.service << EOF
[Unit]
Description=ZFS Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=zfs_exporter
ExecStart=$(which zfs_exporter) \
  --web.listen-address=:9134 \
  --web.disable-exporter-metrics

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart zfs_exporter
sudo systemctl enable zfs_exporter
systemctl status --no-pager zfs_exporter.service
sudo journalctl -b -u zfs_exporter

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/zfs-exporter/pdf/env/

[ -f ./metrics/zfs-exporter/pdf/env/targets-patch.yaml ] ||
  cp ./metrics/zfs-exporter/pdf/scrape-patch.template.yaml ./metrics/zfs-exporter/pdf/env/scrape-patch.yaml

# adjust cluster_type and cluster to your needs
# repeat if you need to scrape several clusters with different names
 cat << EOF >> ./metrics/zfs-exporter/pdf/env/scrape-patch.yaml
  - labels:
      job: zfs-exporter
      cluster_type: pve
      cluster: cluster-name
    targets:
    - node1.example.com:9134
    - node2.example.com:9134
    - node3.example.com:9134
EOF

kl apply -k ./metrics/zfs-exporter/pdf/
kl -n prometheus describe scrapeconfig external-zfs-exporter

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/pdf/
```

# Manual metric checking

```bash

# ip or domain name
node=
curl -sS --insecure http://$node:9134/metrics > ./zfs-exporter-pdf.log

```

# Alerts

References:
- https://samber.github.io/awesome-prometheus-alerts/rules.html#zfs
