
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
helm show values vm/victoria-logs-single --version 0.9.6 > ./metrics/victoria-metrics/victoria-logs/default-values.yaml

helm repo add vector https://helm.vector.dev
helm repo update vector
helm search repo vector/vector --versions --devel | head
helm show values vector/vector --version 0.42.1 > ./metrics/victoria-metrics/vector/default-values.yaml
```

```bash

helm template \
  logs \
  vm/victoria-logs-single \
  --version 0.9.6 \
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

```

# Deploy

```bash

mkdir -p ./metrics/victoria-metrics/env/
clusterName=
 cat << EOF > ./metrics/victoria-metrics/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/-
  value:
    targetLabel: cluster
    replacement: $clusterName
    action: replace
EOF

kl create ns victoria-metrics
kl label ns victoria-metrics pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/victoria-metrics/victoria-logs/
kl -n victoria-metrics get pod -o wide
kl -n victoria-metrics logs sts/vlogs-server-0

# TODO add a separate domain for queries?
kl apply -k ./metrics/victoria-metrics/victoria-logs/httproute-private/
kl -n victoria-metrics get htr

kl apply -k ./metrics/victoria-metrics/vector/
kl -n victoria-metrics get pod -o wide

```

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
