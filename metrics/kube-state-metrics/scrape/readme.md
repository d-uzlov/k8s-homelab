
# Prometheus scrape config

```bash

mkdir -p ./metrics/kube-state-metrics/scrape/env/
 cat << EOF > ./metrics/kube-state-metrics/scrape/env/patch-cluster-tag.yaml
- op: add
  path: /spec/staticConfigs/0/labels/cluster
  value: cluster-name
EOF

kl apply -k ./metrics/kube-state-metrics/scrape/

```

# Manual metric checking

```bash
kl -n kube-state-metrics describe svc ksm
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://ksm.kube-state-metrics:8080/metrics > ./ksm.log
```
