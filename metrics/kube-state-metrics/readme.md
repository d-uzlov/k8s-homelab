
# node-exporter in k8s

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community/kube-state-metrics --versions --devel | head
helm show values prometheus-community/kube-state-metrics --version 5.28.0 > ./metrics/kube-state-metrics/default-values.yaml
```

```bash
helm template \
  ksm \
  prometheus-community/kube-state-metrics \
  --version 5.28.0 \
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

# Deploy

```bash

kl create ns kube-state-metrics
kl label ns node-exporter pod-security.kubernetes.io/enforce=baseline
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
kl exec deployments/alpine -- curl -sS http://ksm.kube-state-metrics:8080/metrics > ./ksm.log
```
