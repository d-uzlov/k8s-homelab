
# nvidia_gpu_exporter

References:
- https://github.com/utkuozdemir/nvidia_gpu_exporter

# Install

See installation instructions in the original repository.

# Manual metric checking

```bash

node=
curl -sS $node:9835/metrics > ./nvidia_gpu_exporter-metrics.log

```

# Prometheus scrape config

```bash

 cat << EOF > ./metrics/component-monitoring/nvidia/env/scrape-nvidia_gpu_exporter.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: nvidia-gpu-exporter
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: nvidia-gpu-exporter
      cluster_type: site
      cluster: my-cluster
    targets:
    - harbor1.example.com:9835
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    sourceLabels: [ instance ]
    regex: (.*):\d*
    action: replace
  - action: drop
    sourceLabels: [ __name__ ]
    regex: go_.*|promhttp_.*
EOF

kl apply -f ./metrics/component-monitoring/nvidia/env/scrape-nvidia_gpu_exporter.yaml
kl -n prometheus describe scrapeconfig harbor

kl apply -f ./metrics/component-monitoring/nvidia/alert.yaml
kl -n prometheus describe promrule alert-harbor

```
