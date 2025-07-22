
# prometheus

References:
- https://github.com/prometheus/prometheus/releases

# Prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)
- [RBAC](../readme.md)

# Generate config

```bash

curl -fsSL https://github.com/prometheus/prometheus/raw/refs/heads/main/documentation/examples/rbac-setup.yml > ./metrics/prometheus/rbac.yaml

# customize your storage class and storage size request
mkdir -p ./metrics/prometheus/env/
externalUrl=
# example: externalUrl=prometheus.example.com
# get externalUrl from ingress of httproute
 cat << EOF > ./metrics/prometheus/env/patch-prometheus.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: main
spec:
  externalUrl: https://$externalUrl/
  alerting:
    alertmanagers:
    - name: alertmanager-operated
      port: 9093
  storage:
    volumeClaimTemplate:
      metadata:
        name: db
      spec:
        resources:
          requests:
            storage: 150Gi
        storageClassName: fast
EOF

mkdir -p ./metrics/prometheus/env/
clusterName=
 cat << EOF > ./metrics/prometheus/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: cluster
    replacement: $clusterName
    action: replace
- op: add
  path: /spec/endpoints/1/relabelings/0
  value:
    targetLabel: cluster
    replacement: $clusterName
    action: replace
EOF

```

# Deploy

```bash

kl apply -k ./metrics/prometheus/main/
kl -n prometheus get prometheus
kl -n prometheus describe prometheus
kl -n prometheus get sts
kl -n prometheus get pvc
kl -n prometheus get pod -o wide

kl -n grafana apply -k ./metrics/prometheus/main/grafana-datasource/

# wildcard ingress
kl label ns --overwrite prometheus copy-wild-cert=main
kl apply -k ./metrics/prometheus/main/ingress-wildcard/
kl -n prometheus get ingress

kl apply -k ./metrics/prometheus/main/httproute-private/
kl apply -k ./metrics/prometheus/main/httproute-authentik/
kl -n prometheus get htr
kl -n prometheus describe htr prometheus-main-private
kl -n prometheus describe htr prometheus-main-authentik
kl -n gateways get ap prometheus.prometheus-main-authentik

kl -n prometheus exec sts/prometheus-main -- df -h | grep /prometheus\$

kl -n prometheus-operator logs deployments/prometheus-operator --tail 50

```

To use this prometheus instance with `ServiceMonitor` and other resources,
add `prometheus.io/instance: main` label to them.
Prometheus monitors all namespaces for these objects.

# Cleanup

```bash
kl delete -k ./metrics/prometheus/main/
```

# Manual metric checking

```bash

kl -n prometheus describe svc prometheus
kl exec deployments/alpine -- curl -sS http://prom-main.prometheus:9090/metrics > ./prometheus-metrics.log
kl exec deployments/alpine -- curl -sS http://prometheus-operated.prometheus:8080/metrics > ./prometheus-reloader-metrics.log

```
