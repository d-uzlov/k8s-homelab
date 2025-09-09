
# VictoriaLogs by VictoriaMetrics

References:
- https://docs.victoriametrics.com/helm/victorialogs-single/
- https://github.com/vectordotdev/helm-charts/tree/develop/charts/vector
- https://vector.dev/docs/setup/installation/package-managers/helm/

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update vm
helm search repo vm/victoria-logs-single --versions --devel | head
helm show values vm/victoria-logs-single --version 0.11.7 > ./metrics/victoria-metrics/victoria-logs/default-values.yaml

helm repo add vector https://helm.vector.dev
helm repo update vector
helm search repo vector/vector --versions --devel | head
helm show values vector/vector --version 0.42.1 > ./metrics/victoria-metrics/vector/default-values.yaml
```

```bash

helm template \
  logs \
  vm/victoria-logs-single \
  --version 0.11.7 \
  --values ./metrics/victoria-metrics/victoria-logs/values.yaml \
  --namespace victoria-metrics \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' -e '\|creationTimestamp: null|d' \
  > ./metrics/victoria-metrics/victoria-logs/victoria-logs.gen.yaml

helm template \
  vector \
  vector/vector \
  --version 0.42.1 \
  --values ./metrics/victoria-metrics/vector/values.yaml \
  --namespace victoria-metrics \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' -e '\|creationTimestamp: null|d' \
  > ./metrics/victoria-metrics/vector/vector.gen.yaml

yq -i '
  del(
    select(
      .kind == "ConfigMap" and
      .metadata.name == "vector"
    )
  )
' ./metrics/victoria-metrics/vector/vector.gen.yaml

```

# Deploy

```bash

mkdir -p ./metrics/victoria-metrics/env/
clusterName=
 cat << EOF > ./metrics/victoria-metrics/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/-
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

mkdir -p ./metrics/victoria-metrics/victoria-logs/env/
storage_class=
size=3Gi
 cat << EOF > ./metrics/victoria-metrics/victoria-logs/env/patch-pvc-template.yaml
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: vlogs-server
  namespace: victoria-metrics
spec:
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: server-volume
    spec:
      storageClassName: $storage_class
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: $size
EOF

kl create ns victoria-metrics
kl label ns victoria-metrics pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/victoria-metrics/victoria-logs/
kl -n victoria-metrics get pvc
kl -n victoria-metrics get pod -o wide
kl -n victoria-metrics logs sts/vlogs-server-0

# TODO add a separate domain for queries?
kl apply -k ./metrics/victoria-metrics/victoria-logs/httproute-private/
kl apply -k ./metrics/victoria-metrics/victoria-logs/httproute-authentik/
kl -n victoria-metrics get htr

kl apply -k ./metrics/victoria-metrics/vector/
kl -n victoria-metrics get pod -o wide

kl -n grafana apply -k ./metrics/victoria-metrics/victoria-logs/grafana-datasource/

```

Grafana integration:
- Plugin: https://grafana.com/grafana/plugins/victoriametrics-logs-datasource/?tab=overview
- Example dashboard: https://grafana.com/grafana/dashboards/22759-victorialogs-explorer/

# Cleanup

```bash
kl delete -k ./metrics/victoria-metrics/victoria-logs/
kl delete -k ./metrics/victoria-metrics/vector/
kl delete ns victoria-metrics
```

# Manual metric checking

```bash

kl -n victoria-metrics describe svc vlogs-server
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://vlogs-server.victoria-metrics:9428/metrics > ./vlogs-metrics.log

```
