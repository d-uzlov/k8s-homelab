
# Node exporter outside of k8s cluster

# Linux installation

References:
- https://computingforgeeks.com/how-to-install-prometheus-and-node-exporter-on-debian/
- https://prometheus.io/docs/guides/node-exporter/#installing-and-running-the-node-exporter

Run on the target system:

```bash

# https://github.com/prometheus/node_exporter/releases
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.9.1.linux-amd64.tar.gz

# when updating, stop service to allow to replace binary file
sudo systemctl stop node_exporter
sudo cp ./node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/

sudo groupadd --system node_exporter
sudo useradd -s /sbin/nologin --system -g node_exporter node_exporter

 sudo tee /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter \\
  --collector.diskstats.device-exclude='^(loop.*)$' \\
  --collector.netdev.device-exclude='^(fwbr.*|fwln.*|fwpr.*|tap.*|veth.*)$' \\
  --collector.netclass.ignore-invalid-speed \\
  --collector.netdev.address-info \\
  --collector.textfile.directory=/tmp/node-exporter-textfile/ \\
  --no-collector.netstat \\
  --no-collector.nfsd \\
  --no-collector.sockstat \\
  --no-collector.softnet \\
  --no-collector.udp_queues \\
  --no-collector.infiniband \\
  --web.listen-address=:9100 \\
  --web.disable-exporter-metrics

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart node_exporter
sudo systemctl enable node_exporter
systemctl status --no-pager node_exporter.service
sudo journalctl -b -u node_exporter

```

# Prometheus scrape config

```bash
mkdir -p ./metrics/node-exporter/scrape/env/

# if you already have scrape-patch.yaml, add more objects into staticConfigs list
 cat << EOF > ./metrics/node-exporter/scrape/env/scrape-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-node-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      cluster_type: pve
      cluster: cluster-name
    targets:
    - node1.example.com:9100
    - node2.example.com:9100
EOF

kl apply -k ./metrics/node-exporter/scrape/

```

# Manual metric checking

```bash

node=
curl -sS --insecure http://$node:9100/metrics > ./node-exporter.log

```
