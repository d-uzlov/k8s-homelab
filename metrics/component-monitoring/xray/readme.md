
# V2Ray Exporter

References:
- https://github.com/wi1dcard/v2ray-exporter/tree/master

# Deploy

Run on the xray system:

```bash

wget -O /tmp/v2ray-exporter https://github.com/wi1dcard/v2ray-exporter/releases/latest/download/v2ray-exporter_linux_amd64
chmod +x /tmp/v2ray-exporter
sudo mv /tmp/v2ray-exporter /usr/local/bin/v2ray-exporter

sudo groupadd --system v2ray-exporter
sudo useradd -s /sbin/nologin --system -g v2ray-exporter v2ray-exporter

# adjust your api port before creating service

 sudo tee /etc/systemd/system/v2ray-exporter.service << EOF
[Unit]
Description=v2ray-exporter
Wants=network-online.target
After=network-online.target

[Service]
User=v2ray-exporter
ExecStart=/usr/local/bin/v2ray-exporter \
  --v2ray-endpoint=127.0.0.1:62790 \
  --metrics-path=/scrape \
  --listen=:9550

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart v2ray-exporter
sudo systemctl enable v2ray-exporter
systemctl status --no-pager v2ray-exporter
sudo journalctl -b -u v2ray-exporter

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/component-monitoring/xray/env/

[ -f ./metrics/component-monitoring/xray/env/targets-patch.yaml ] ||
  cp ./metrics/component-monitoring/xray/scrape-patch.template.yaml ./metrics/component-monitoring/xray/env/scrape-patch.yaml

# adjust cluster_type and cluster to your needs
# repeat if you need to scrape several clusters with different names
 cat << EOF >> ./metrics/component-monitoring/xray/env/scrape-patch.yaml
  - labels:
      job: xray
      cluster_type: xray
      cluster: cluster-name
    targets:
    - xray.example.com:9550
EOF

kl apply -k ./metrics/component-monitoring/xray/

```

# Manual metric checking

```bash
# ip or domain name
node=
curl -sS http://$node:9550/scrape > ./xray-exporter.log
```
