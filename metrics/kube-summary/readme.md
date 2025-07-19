
# Kube summary

K8s node storage metrics

References:
- https://github.com/utilitywarehouse/kube-summary-exporter

# Generate config

```bash

wget https://github.com/utilitywarehouse/kube-summary-exporter/raw/refs/tags/v0.4.5/manifests/cluster/clusterrole.yaml -O ./metrics/kube-summary/rbac.yaml
wget https://github.com/utilitywarehouse/kube-summary-exporter/raw/refs/tags/v0.4.5/manifests/base/deployment.yaml -O ./metrics/kube-summary/deployment.yaml

```

# Local config setup

```bash

mkdir -p ./metrics/kube-summary/env/
clusterName=
 cat << EOF > ./metrics/kube-summary/env/patch-cluster-tag.yaml
- op: add
  path: /spec/staticConfigs/0/labels/cluster
  value: $clusterName
EOF

```

# Deploy

```bash

kl create ns kube-summary
kl label ns kube-summary pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/kube-summary/
kl -n kube-summary get pod -o wide

kl apply -k ./metrics/kube-summary/dashboards/ --server-side

```

Don't forget to deploy Grafana dashboards:
- [Dashboards](./dashboards/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/kube-summary/
kl delete ns kube-summary
```

# Manual metric checking

```bash

kl -n kube-summary describe svc kube-summary-exporter

kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://kube-summary-exporter.kube-summary:9779/metrics > ./kube-summary-metrics.log
kl exec deployments/alpine -- curl -sS http://kube-summary-exporter.kube-summary:9779/nodes > ./kube-summary-nodes.log

```
