
# Deploy

```bash

mkdir -p ./metrics/component-monitoring/k8s-control-plane/static-pod-style/env/
clusterName=
 cat << EOF > ./metrics/component-monitoring/k8s-control-plane/static-pod-style/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

kl apply -k ./metrics/component-monitoring/k8s-control-plane/static-pod-style/

```

# cleanup

```bash
kl delete -k ./metrics/component-monitoring/k8s-control-plane/static-pod-style/
```

# apiserver

Manual metric checking:

```bash

bearer=$(kl -n prometheus get secrets prometheus-sa-token -o json | jq -r '.data.token' | base64 -d)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kubernetes.default:443/metrics > ./apiserver-metrics.log

```

# kube-controller-manager

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

bearer=$(kl -n prometheus get secrets prometheus-sa-token -o json | jq -r '.data.token' | base64 -d)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kube-controller-manager.kube-system:10257/metrics > ./kube-controller-manager-metrics.log

```

# kube-scheduler

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

bearer=$(kl -n prometheus get secrets prometheus-sa-token -o json | jq -r '.data.token' | base64 -d)
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kube-scheduler.kube-system:10259/metrics > ./kube-scheduler-metrics.log

```

# coredns

Coredns is not monitored at all here.

But you can check its metrics manually:

```bash
kl exec deployments/alpine -- curl -sS http://kube-dns.kube-system:9153/metrics > ./coredns-metrics.log
```
