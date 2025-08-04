
# Metrics for disk SMART parameters

# Linux installation

References:
- https://github.com/prometheus-community/smartctl_exporter

Run on the target system:

```bash

sudo apt remove smartmontools

# we are installing smartctl from sources because
# - most distributions have outdated version
# - smartctl doesn't have docker image, or anything similar
# - smartctl is a broken mess that absolutely requires updates

sudo apt install make g++

# https://github.com/smartmontools/smartmontools/releases
wget -q https://github.com/smartmontools/smartmontools/releases/download/RELEASE_7_5/smartmontools-7.5.tar.gz
tar zxvf smartmontools-7.5.tar.gz
cd smartmontools-7.5
./configure
make
sudo make install
cd ..

# update database for smartctl from apt
sudo /usr/sbin/update-smart-drivedb
# update database for smartctl from 'make install'
sudo /usr/local/sbin/update-smart-drivedb

# https://github.com/prometheus-community/smartctl_exporter/releases
# wget -q https://github.com/prometheus-community/smartctl_exporter/releases/download/v0.14.0/smartctl_exporter-0.14.0.linux-amd64.tar.gz
# tar xvfz smartctl_exporter-0.14.0.linux-amd64.tar.gz

# using customized smartctl_exporter to get stable device names
sudo systemctl stop smartctl_exporter
wget -q https://github.com/d-uzlov/smartctl_exporter/releases/download/1.14.0-device-id/smartctl_exporter-amd64
chmod +x smartctl_exporter-amd64

 sudo tee /etc/systemd/system/smartctl_exporter.service << EOF
[Unit]
Description=smartctl_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=$(which ~/smartctl_exporter-amd64) \\
  --smartctl.path=/usr/local/sbin/smartctl \\
  --smartctl.interval=60s \\
  --smartctl.rescan=10m \\
  --smartctl.device-include=".*" \\
  --smartctl.powermode-check="standby" \\
  --web.listen-address=:9633 \\
  --log.level=info \\
  --log.format=logfmt

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl stop smartctl_exporter
sudo systemctl restart smartctl_exporter
sudo systemctl enable smartctl_exporter
systemctl status --no-pager smartctl_exporter.service
sudo journalctl -b -u smartctl_exporter

```

# Windows setup

Download the binary here:
- https://github.com/d-uzlov/smartctl_exporter/releases/download/1.14.0-device-id/smartctl_exporter-win64.exe

```powershell

# adjust for your binary path
nssm install smartctl_exporter c:\Users\user\programs\smartctl_exporter-win64.exe --smartctl.path=smartctl --smartctl.interval=60s --smartctl.rescan=10m --smartctl.device-include=".*" --smartctl.powermode-check="standby" --web.listen-address=:9633 --log.level=info --log.format=logfmt

nssm edit smartctl_exporter

```

Ensure the following argument is present in the edit window: `"--smartctl.path=c:\Program Files\smartmontools\bin\smartctl.exe"`

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
      job: smartctl-exporter
      cluster_type: site
      cluster: my-cluster
    targets:
    - example.com:9633
  relabelings:
  - targetLabel: instance
    sourceLabels: [ __address__ ]
    regex: (.*):\d*
    action: replace
  metricRelabelings:
  - action: drop
    sourceLabels: [ __name__ ]
    regex: go_gc_.*|process_.*
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

# TODO

Investigate Seagate read error rate:
- https://github.com/smartmontools/smartmontools/issues/220
- https://serverfault.com/questions/313649/how-to-interpret-this-smartctl-smartmon-data
