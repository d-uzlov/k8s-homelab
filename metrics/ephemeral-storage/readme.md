
# K8s Ephemeral Storage Metrics

References:
- https://github.com/jmcgrath207/k8s-ephemeral-storage-metrics

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add k8s-ephemeral-storage-metrics https://jmcgrath207.github.io/k8s-ephemeral-storage-metrics/chart
helm repo update k8s-ephemeral-storage-metrics
helm search repo k8s-ephemeral-storage-metrics/k8s-ephemeral-storage-metrics --versions --devel | head
helm show values k8s-ephemeral-storage-metrics/k8s-ephemeral-storage-metrics --version 1.18.0 > ./metrics/ephemeral-storage/default-values.yaml
```

```bash

helm template \
  ephemeral-storage \
  k8s-ephemeral-storage-metrics/k8s-ephemeral-storage-metrics \
  --version 1.18.0 \
  --values ./metrics/ephemeral-storage/values.yaml \
  --namespace ephemeral-storage \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' -e '\|creationTimestamp: null|d' \
  | sed -e 's/name: k8s-ephemeral-storage-metrics/name: esm/' \
  > ./metrics/ephemeral-storage/ephemeral-storage.gen.yaml

```

# Local config setup

```bash

mkdir -p ./metrics/ephemeral-storage/env/
clusterName=
 cat << EOF > ./metrics/ephemeral-storage/env/patch-cluster-tag.yaml
- op: add
  path: /spec/staticConfigs/0/labels/cluster
  value: $clusterName
EOF

```

# Deploy

```bash

kl create ns ephemeral-storage
kl label ns ephemeral-storage pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/ephemeral-storage/
kl -n ephemeral-storage get pod -o wide

kl apply -k ./metrics/ephemeral-storage/dashboards/ --server-side

```

Don't forget to deploy Grafana dashboards:
- [Dashboards](./dashboards/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/ephemeral-storage/
kl delete ns ephemeral-storage
```

# Manual metric checking

```bash

kl -n ephemeral-storage describe svc esm

# pick some node randomly
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS --insecure http://esm.ephemeral-storage:9100/metrics > ./esm-metrics-kubelet.log

```
