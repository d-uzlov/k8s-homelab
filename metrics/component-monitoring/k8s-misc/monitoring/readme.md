
# Deploy

```bash

mkdir -p ./metrics/component-monitoring/k8s-misc/monitoring/env/
clusterName=
 cat << EOF > ./metrics/component-monitoring/k8s-misc/monitoring/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/-
  value:
    targetLabel: cluster
    replacement: $clusterName
EOF

kl apply -k ./metrics/component-monitoring/k8s-misc/monitoring/

```

# apiserver

Apiserver monitoring is only used for alerting.

Manual metric checking:

```bash

bearer=$(kl -n prometheus exec sts/prometheus-main -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kubernetes.default:443/metrics

```

# kube-controller-manager

kube-controller-manager monitoring is only used for `kubernetes_build_info` checking.

Make sure that kube controller manager is listening on `0.0.0.0` to allow prometheus to connect to it.

For example, if you are using kubeadm, adjust its config:

```yaml
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0
```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

Manual metric checking:

```bash

bearer=$(kl -n prometheus exec sts/prometheus-main -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kps-kube-controller-manager.kube-system:10257/metrics

```

# kube-scheduler

kube-scheduler monitoring is only used for `kubernetes_build_info` checking.

Make sure that kube scheduler is listening on `0.0.0.0` to allow prometheus to connect to it.

For example, if you are using kubeadm, adjust its config:

```yaml
scheduler:
  extraArgs:
    bind-address: 0.0.0.0
```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

Manual metric checking:

```bash

bearer=$(kl -n prometheus exec sts/prometheus-main -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kps-kube-scheduler.kube-system:10259/metrics

```

# coredns

Coredns is not monitored at all here.

But you can check its metrics manually:

```bash
kl exec deployments/alpine -- curl -sS http://kube-dns.kube-system:9153/metrics
```
