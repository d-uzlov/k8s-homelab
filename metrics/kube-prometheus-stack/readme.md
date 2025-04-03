
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
helm show values prometheus-community/kube-prometheus-stack --version 67.4.0 > ./metrics/kube-prometheus-stack/default-values.yaml
```

```bash
function remove_helm_junk() {
  sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '\|release: kps|d' \
    -e '\|67.4.0|d' \
    -e '/^ *$/d' \
    -e '\|heritage\:|d' \
    -e '\|httpHeaders\:$|d'
}
function generateDeployment() {
  args=
  for arg in $*; do
    args="$args --set $arg"
  done
  helm template \
    kps \
    prometheus-community/kube-prometheus-stack \
    --version 67.4.0 \
    --values ./metrics/kube-prometheus-stack/values.yaml \
    $args \
    | remove_helm_junk
}

generateDeployment grafana.defaultDashboardsEnabled=true \
                   grafana.forceDeployDashboards=true \
                                                    > ./metrics/kube-prometheus-stack/grafana/grafana-default-dashboards.gen.yaml

```

# Deploy

```bash
# deploys default grafana dashboards from kps
kl apply -k ./metrics/kube-prometheus-stack/grafana/

```

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/grafana/
kl delete ns kps-grafana
```
