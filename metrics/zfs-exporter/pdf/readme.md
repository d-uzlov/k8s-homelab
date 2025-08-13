
# ZFS exporter outside of k8s cluster

# Prerequisites

- [Golang](../../../docs/golang.md#install)

# Linux installation

References:
- https://github.com/pdf/zfs_exporter

Run on the target system:

```bash

sudo apt-get update
sudo apt-get install -y git

# https://github.com/pdf/zfs_exporter/releases
zfs_exporter_version=v2.3.8
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
ExecStart=$(which zfs_exporter) \\
  --web.listen-address=:9134 \\
  --properties.dataset-filesystem="available,logicalused,quota,referenced,used,usedbydataset,usedbychildren,usedbysnapshots,written,refquota,refreservation,reservation,snapshot_count,snapshot_limit,logicalreferenced,creation" \\
  --properties.dataset-volume="available,logicalused,referenced,used,usedbydataset,volsize,written,usedbysnapshots,logicalreferenced,creation,snapshot_count" \\
  --properties.pool="allocated,dedupratio,capacity,expandsize,fragmentation,free,freeing,health,leaked,readonly,size" \\
  --web.disable-exporter-metrics

[Install]
WantedBy=default.target
EOF

zfs_exporter \
  --web.listen-address=:9135 \
  --properties.dataset-filesystem="available,logicalused,quota,referenced,used,usedbydataset,usedbychildren,usedbysnapshots,written,refquota,refreservation,reservation,snapshot_count,snapshot_limit,logicalreferenced,creation" \
  --properties.dataset-volume="available,logicalused,referenced,used,usedbydataset,volsize,written,usedbysnapshots,logicalreferenced,creation,snapshot_count" \
  --properties.pool="allocated,dedupratio,capacity,expandsize,fragmentation,free,freeing,health,leaked,readonly,size" \
  --web.disable-exporter-metrics


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
# if scrape-patch.yaml already exists, add more items into staticConfigs list
 cat << EOF >> ./metrics/zfs-exporter/pdf/env/scrape-patch.yaml
 ---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-zfs-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      job: zfs-exporter
      location: cluster-name
    targets:
    - node1.example.com:9134
    - node2.example.com:9134
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
