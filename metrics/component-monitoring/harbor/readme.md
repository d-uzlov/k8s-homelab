
# harbor

See [harbor](../../../k8s-core/docs/harbor/harbor.md)

# Manual metric checking

```bash

harbor_node=
curl -sS $harbor_node:9090/metrics > ./harbor-metrics.log

```

# Prometheus scrape config

```bash

 cat << EOF > ./metrics/component-monitoring/harbor/env/scrape-harbor.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: harbor
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: harbor
      cluster_type: harbor
      cluster: my-cluster
    targets:
    - harbor1.example.com:9090
  relabelings:
  - targetLabel: instance # remove port from instance
    sourceLabels: [ __address__ ]
    regex: (.*):\d*
    action: replace
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    sourceLabels: [ instance ]
    regex: (.*):9090
    action: replace
  - action: drop
    sourceLabels: [ __name__ ]
    regex: go_.*|promhttp_.*
EOF

kl apply -f ./metrics/component-monitoring/harbor/env/scrape-harbor.yaml
kl -n prometheus describe scrapeconfig harbor

kl apply -f ./metrics/component-monitoring/harbor/alert.yaml
kl -n prometheus describe promrule alert-harbor

```
