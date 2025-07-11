
# Metrics for disk SMART parameters

# Linux installation

References:
- https://github.com/prometheus-community/smartctl_exporter

Run on the target system:

```bash

sudo apt install -y smartmontools

# https://github.com/prometheus-community/smartctl_exporter/releases
wget -q https://github.com/prometheus-community/smartctl_exporter/releases/download/v0.14.0/smartctl_exporter-0.14.0.linux-amd64.tar.gz
tar xvfz smartctl_exporter-0.14.0.linux-amd64.tar.gz

 sudo tee /etc/systemd/system/smartctl_exporter.service << EOF
[Unit]
Description=smartctl_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=$(which ~/smartctl_exporter-0.14.0.linux-amd64/smartctl_exporter) \\
  --smartctl.interval=60s \\
  --smartctl.rescan=10m \\
  --smartctl.device-include=".*" \\
  --smartctl.powermode-check="standby" \\
  --smartctl.scan-device-type=by-id \\
  --web.listen-address=:9633 \\
  --log.level=info \\
  --log.format=logfmt

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart smartctl_exporter
sudo systemctl enable smartctl_exporter
systemctl status --no-pager smartctl_exporter.service
sudo journalctl -b -u smartctl_exporter

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/smart/env/

# adjust cluster_type and cluster to your needs
# repeat if you need to scrape several clusters with different names
 cat << EOF > ./metrics/smart/env/scrape-smartctl.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-smart
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: smartctl_exporter
      cluster_type: nas
      cluster: my-cluster
    targets:
    - example.com:9633
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    sourceLabels: [ instance ]
    regex: (.*):\d*
    action: replace
  - action: drop
    sourceLabels: [ __name__ ]
    regex: node_cpu_scaling_governor
EOF

kl apply -f ./metrics/smart/env/scrape-smartctl.yaml
kl -n prometheus describe scrapeconfig external-smart

kl apply -f ./metrics/smart/alert.yaml

```

# Cleanup

```bash
kl delete -k ./metrics/smart/
```

# Manual metric checking

```bash

# ip or domain name
node=
curl -sS --insecure http://$node:9633/metrics > ./smartctl_exporter.log

```
