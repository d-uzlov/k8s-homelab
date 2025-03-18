
# prometheus-operator

If you want to upgrade, consult this:
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/UPGRADE.md

You need to manually upgrade CRDs.
Some upgrades need a migration.

References:
- https://technotim.live/posts/kube-grafana-prometheus/
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://github.com/prometheus-operator/kube-prometheus

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community/kube-prometheus-stack --versions --devel | head
helm show values prometheus-community/kube-prometheus-stack --version 70.0.2 > ./metrics/prometheus-operator/default-values.yaml
```

```bash

helm template \
  prometheus-operator \
  prometheus-community/kube-prometheus-stack \
  --version 70.0.2 \
  --values ./metrics/prometheus-operator/values.yaml \
  --namespace prometheus-operator \
  | sed \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '/^ *$/d' \
    -e '\|heritage\:|d' \
    -e '\|release\:|d' \
    -e '\|chart\:|d' \
  > ./metrics/prometheus-operator/prometheusOperator.gen.yaml

```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

# Deploy

```bash

kl apply -f ./metrics/prometheus-operator/crd/ --server-side

kl create ns prometheus-operator
kl label ns prometheus-operator pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/prometheus-operator/
kl -n prometheus-operator get pod -o wide

```

Don't forget to deploy additional dashboards:
- [k8s](./component-monitors/k8s/readme.md)
- [etcd](./component-monitors/etcd/readme.md)
- [proxmox](./component-monitors/proxmox/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/prometheus-operator/
kl delete ns prometheus-operator
kl delete -f ./metrics/prometheus-operator/crd/
```

# Manual metric checking

```bash

kl -n prometheus-operator describe svc prometheus-operator
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS --insecure https://prometheus-operator.prometheus-operator/metrics

```
