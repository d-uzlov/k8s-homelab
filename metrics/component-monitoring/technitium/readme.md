
# Technitium exporter

References:
- https://github.com/NathanPERIER/technitium-dns-prometheus-exporter
- https://hub.docker.com/r/foxxmd/technitium-dns-exporter

Data in proxmox updates every 20 seconds.

# Local environment

```bash

mkdir -p mkdir -p ./metrics/component-monitoring/technitium/env/

 cat << EOF > ./metrics/component-monitoring/technitium/env/config.env
# _DNS_ is used as server _label_
# change it to something meaningful
# you can repeat _BASE_URL and _TOKEN for querying several servers,
# using different _label_ value
TECHNITIUM_API_DNS_BASE_URL=http://technitium.example.com:5380
TECHNITIUM_API_DNS_TOKEN=qwe123
# add _LABEL env with the same _label_ if you want actual label
# to be something not expressible as part of env name
TECHNITIUM_API_DNS_LABEL=dns
EOF

```

# Deploy

```bash

kl create ns technitium-exporter
kl label ns technitium-exporter pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/component-monitoring/technitium/
kl -n technitium-exporter get pod -o wide

```

TODO the metrics are nonsense:
- there are no counters
- gauges ending with `_count` seems to update once every minute
- "_during the past hour_": what kind of a metrics is this?

# Cleanup

```bash
kl delete -k ./metrics/component-monitoring/technitium/
kl delete ns technitium-exporter
```

# Manual metric checking

```bash

kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS "http://technitium-exporter.technitium-exporter:80/metrics" > ./technitium-metrics.log

```

# Prometheus scrape config

```bash

 cat << EOF > ./metrics/component-monitoring/technitium/env/scrape-technitium.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: technitium-exporter
  namespace: technitium-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: technitium
      location: my-cluster
    targets:
    - technitium-exporter.technitium-exporter
  metricRelabelings:
  - action: labeldrop
    regex: instance
EOF

kl apply -f ./metrics/component-monitoring/technitium/env/scrape-technitium.yaml
kl -n technitium-exporter describe scrapeconfig technitium-exporter

```
