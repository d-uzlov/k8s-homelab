
# prompp

References:
- https://github.com/deckhouse/prompp/releases

# prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)

# config

```bash

mkdir -p ./metrics/prometheus/prompp/env/

# customize your patch manually

 cat << EOF > ./metrics/prometheus/prompp/env/patch-prometheus.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prompp
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

 cat << EOF > ./metrics/prometheus/prompp/env/patch-location-tag.yaml
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

kl apply -k ./metrics/prometheus/prompp/
kl -n prometheus get prom
kl -n prometheus get pod -o wide

kl -n grafana apply -k ./metrics/prometheus/prompp/grafana-datasource/

kl apply -k ./metrics/prometheus/prompp/httproute-private/
kl apply -k ./metrics/prometheus/prompp/httproute-protected/
kl -n prometheus get htr

```

To use this prometheus instance with `ServiceMonitor` and other resources,
add `instance.prometheus.io/prompp: enable` label to them.
Prometheus monitors all namespaces for these objects.

# cleanup

```bash
kl delete -k ./metrics/prometheus/prompp/
```

# manual metric checking

```bash

kl -n prometheus describe svc prometheus
kl exec deployments/alpine -- curl -sS http://prom-prompp.prometheus:9090/metrics > ./prometheus-metrics.log
kl exec deployments/alpine -- curl -sS http://prom-prompp.prometheus:8080/metrics > ./prometheus-reloader-metrics.log

```
