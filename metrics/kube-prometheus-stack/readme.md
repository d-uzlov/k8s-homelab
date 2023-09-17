
# kube-prometheus-stack

If you want to upgrade, consult this: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

Different versions have different deploy commands.

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
helm show values prometheus-community/kube-prometheus-stack --version 51.0.3 > ./metrics/kube-prometheus-stack/default-values.yaml
```

```bash
helm template \
  kps \
  prometheus-community/kube-prometheus-stack \
  --version 51.0.3 \
  --values ./metrics/kube-prometheus-stack/values.yaml \
  --namespace kps \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  | sed -e 's/"interval":"1m"/"interval":"10s"/g'  \
  > ./metrics/kube-prometheus-stack/deployment.gen.yaml
```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

# Deploy

```bash
kl apply -k ./metrics/kube-prometheus-stack/crd/ --server-side

kl create ns kps

kl apply -k ./metrics/kube-prometheus-stack/
# kl apply -k ./metrics/kube-prometheus-stack/ --server-side=true
kl -n kps get pod

# setup wildcard ingress
kl label ns --overwrite kps copy-wild-cert=main
kl apply -k ./metrics/kube-prometheus-stack/ingress-wildcard/
kl -n kps get ingress
```

Default username/password is `admin` / `prom-operator`.

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/
kl delete ns kps
kl delete -k ./metrics/kube-prometheus-stack/crd/
```

# kube-controller-manager and kube-scheduler metrics

If you want to see metrics from kube-controller-manager and kube-scheduler,
you need to change its configs to bind to node IP instead of localhost.

If you use kubeadm for cluster setup,
you can edit kubeadm config to make changes persistent:

```bash
kl edit -n kube-system cm kubeadm-config
```

Make sure you have the following additional `extraArgs` values listed:

```yaml
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0
scheduler:
  extraArgs:
    bind-address: 0.0.0.0
```

After you change kubeadm-config, you need to apply new config on all master nodes:

```bash
sudo kubeadm upgrade node
```

# etcd metrics

If you want to see metrics from etcd, you need to provide special mTLS certificate to prometheus.

You can use the following commands to extract the certificate from cluster:

```bash
kl apply -f ./metrics/kube-prometheus-stack/cert-extractor.yaml

kl wait -n kps --for=condition=ready pods/cert-extractor

kl cp kps/cert-extractor:/etc/kubernetes/pki/etcd/ca.crt ./metrics/kube-prometheus-stack/env/ca.crt &&
kl cp kps/cert-extractor:/etc/kubernetes/pki/etcd/healthcheck-client.crt ./metrics/kube-prometheus-stack/env/healthcheck-client.crt &&
kl cp kps/cert-extractor:/etc/kubernetes/pki/etcd/healthcheck-client.key ./metrics/kube-prometheus-stack/env/healthcheck-client.key

kl -n kps delete pod cert-extractor
```

# TODO

Maybe it's better to change default k8s metrics polling interval.
Even if prometheus polls metrics each second,
k8s metrics are updated only once every 10 seconds, or slower.

Keywords: `housekeeping-interval`.
