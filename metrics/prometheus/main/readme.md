
# prometheus

References:
- https://github.com/prometheus/prometheus/releases

# prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)
- [RBAC](../readme.md)

# config

```bash

mkdir -p ./metrics/prometheus/main/env/

# customize your patch manually

 cat << EOF > ./metrics/prometheus/env/patch-prometheus.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: main
spec:
  retention: 90d
  retentionSize: 145GiB
  # get externalUrl from ingress or httproute
  externalUrl: https://prometheus.example.com/
  alerting:
    alertmanagers:
    - name: alertmanager-operated
      # namespace: prometheus
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

clusterName=

 cat << EOF > ./metrics/prometheus/main/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
- op: add
  path: /spec/endpoints/1/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

```

# deploy

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
kl apply -k ./metrics/prometheus/main/httproute-protected/
kl -n prometheus get htr

kl -n prometheus exec sts/prometheus-main -- df -h | grep /prometheus\$

kl -n prometheus-operator logs deployments/prometheus-operator --tail 50

```

To use this prometheus instance with `ServiceMonitor` and other resources,
add `prometheus.io/instance: main` label to them.
Prometheus monitors all namespaces for these objects.

# cleanup

```bash
kl delete -k ./metrics/prometheus/main/
```

# manual metric checking

```bash

kl -n prometheus describe svc prometheus
kl exec deployments/alpine -- curl -sS http://prom-main.prometheus:9090/metrics > ./prometheus-metrics.log
kl exec deployments/alpine -- curl -sS http://prom-main.prometheus:8080/metrics > ./prometheus-reloader-metrics.log

```
