
# cadvisor metrics

This cadvisor deployment is not standalone nodes.

References:
- https://github.com/prometheus-community/systemd_exporter

# Prerequisites

- [Docker](../../../docs/proxmox/proxmox-container.md#docker)

# Linux installation

Run on the target system:

```bash

mkdir ~/cadvisor/
cd ~/cadvisor/

 cat << EOF > ~/cadvisor/docker-compose.yaml
services:
  cadvisor:
    privileged: true
    image: ghcr.io/google/cadvisor:v0.53.0
    command:
    - --port=8999
    - --allow_dynamic_housekeeping=true
    - --housekeeping_interval=2s
    - --max_housekeeping_interval=3s
    - --event_storage_event_limit=default=0
    - --event_storage_age_limit=default=0
    - --enable_metrics=cpu,diskIO,memory,network,pressure,process
    - --docker_only
    - --raw_cgroup_prefix_whitelist=/system.slice,/qemu.slice,/lxc,/lxc.monitor
    - --store_container_labels=false
    - --whitelisted_container_labels=com.docker.compose.image,com.docker.compose.service,com.docker.compose.project
    ports:
    - 8999:8999
    volumes:
    - /:/rootfs:ro
    - /sys:/sys:ro
    - /var/run:/var/run:ro
    - /var/lib/docker/:/var/lib/docker:ro
    - /dev/disk/:/dev/disk:ro
EOF

docker compose up -d
docker compose logs

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/cadvisor/cadvisor-external/env/

location=

# adjust tags to your needs
# if scrape-patch.yaml already exists, add more items into staticConfigs list

 cat << EOF > ./metrics/cadvisor/cadvisor-external/env/scrape-cadvisor-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: cadvisor-external
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      location: $location
    targets:
    - node1.example.com:8999
    - node2.example.com:8999
EOF

kl apply -k ./metrics/cadvisor/cadvisor-external/
kl -n metrics-cadvisor describe scrapeconfig cadvisor-external

```

# Cleanup

```bash
kl delete -k ./metrics/cadvisor/cadvisor-external/
```

# Manual metric checking

```bash

node=
curl -sS http://$node:8999/metrics > ./cadvisor.prom

```
