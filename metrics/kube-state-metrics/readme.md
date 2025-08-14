
# kube-state-metrics

References:
- https://github.com/kubernetes/kube-state-metrics

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community/kube-state-metrics --versions --devel | head
helm show values prometheus-community/kube-state-metrics --version 6.1.0 > ./metrics/kube-state-metrics/default-values.yaml
```

```bash

helm template \
  ksm \
  prometheus-community/kube-state-metrics \
  --version 6.1.0 \
  --values ./metrics/kube-state-metrics/values.yaml \
  --namespace kube-state-metrics \
  | sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '/^ *$/d' \
    -e '\|httpHeaders\:$|d' \
  > ./metrics/kube-state-metrics/kube-state-metrics.gen.yaml

```

# Local config setup

```bash

mkdir -p ./metrics/kube-state-metrics/env/
clusterName=
 cat << EOF > ./metrics/kube-state-metrics/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF
 cat << EOF > ./metrics/kube-state-metrics/env/patch-scrape-location-tag.yaml
- op: add
  path: /spec/staticConfigs/0/labels/location
  value: $clusterName
EOF

```

# Deploy

```bash

kl create ns kube-state-metrics
kl label ns kube-state-metrics pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/kube-state-metrics/
kl -n kube-state-metrics get pod -o wide
kl -n kube-state-metrics get servicemonitor

```

# Cleanup

```bash
kl delete -k ./metrics/kube-state-metrics/
kl delete ns kube-state-metrics
```

# Manual metric checking

```bash

kl -n kube-state-metrics describe svc ksm

kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://ksm.kube-state-metrics:8080/metrics > ./ksm-exported-metrics.log
kl exec deployments/alpine -- curl -sS http://ksm.kube-state-metrics:8081/metrics > ./ksm-own-metrics.log

```
