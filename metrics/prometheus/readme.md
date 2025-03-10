
# prometheus

References:
- https://github.com/prometheus/prometheus/releases

# Prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)

# Generate config

```bash

curl -fsSL https://github.com/prometheus/prometheus/raw/refs/heads/main/documentation/examples/rbac-setup.yml > ./metrics/prometheus/rbac.yaml

# customize your storage class and storage size request
mkdir -p ./metrics/prometheus/env/
externalUrl=
# example: externalUrl=prometheus.example.com
# get externalUrl from ingress of httproute
 cat << EOF > ./metrics/prometheus/env/patch.yaml
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
```

# Deploy

```bash

kl create ns prometheus
kl label ns prometheus pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/prometheus/
kl -n prometheus get prometheus
kl -n prometheus describe prometheus
kl -n prometheus get sts
kl -n prometheus get pvc
kl -n prometheus get pod -o wide

# show list of all relevant prometheus configs
kl get prometheusrule -A
kl get servicemonitor -A
kl get podmonitor -A
kl get scrapeconfig -A
kl get probe -A

# wildcard ingress
kl label ns --overwrite prometheus copy-wild-cert=main
kl apply -k ./metrics/prometheus/ingress-wildcard/
kl -n prometheus get ingress

# private gateway
kl apply -k ./metrics/prometheus/httproute/
kl apply -k ./metrics/prometheus/httproute-protected/
kl -n prometheus get httproute
kl -n prometheus describe httproute prometheus

kl -n prometheus exec sts/prometheus-main -- df -h | grep /prometheus\$
```

To use this prometheus instance with `ServiceMonitor` and other resources,
add `prometheus.io/instance: main` label to them.
Prometheus monitors all namespaces for these objects.

# Cleanup

```bash
kl delete -k ./metrics/prometheus/
kl delete ns prometheus
```

# Manual metric checking

```bash
kl -n prometheus describe svc prometheus
kl exec deployments/alpine -- curl -sS http://prometheus-operated.prometheus:9090/metrics
kl exec deployments/alpine -- curl -sS http://prometheus-operated.prometheus:8080/metrics
```
