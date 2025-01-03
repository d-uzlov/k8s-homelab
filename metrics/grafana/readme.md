

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
helm search repo grafana/grafana --versions --devel | head
helm show values grafana/grafana --version 8.8.2 > ./metrics/grafana/default-values.yaml

helm template \
  grafana \
  grafana/grafana \
  --version 8.8.2 \
  --values ./metrics/grafana/values.yaml \
  --namespace grafana \
  | sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '/^ *$/d' \
    -e '\|httpHeaders\:$|d' \
  > ./metrics/grafana/grafana.gen.yaml

```

# Prerequisites

Grafana will work just fine on its own.

But for it to be useful you need to deploy dashboards to actually see data.

For dashboards to work, you need to deploy
prometheus and related scrape configurations.

- [prometheus](../kube-prometheus-stack/readme.md)
- [kube-state-metrics](../kube-state-metrics/readme.md)
- [node-exporter](../node-exporter/readme.md)

# Deploy

```bash
mkdir -p ./metrics/grafana/env/
 cat << EOF > ./metrics/grafana/env/admin.env
username=admin
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

kl create ns grafana
kl label ns grafana pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/grafana/
kl -n grafana get pod -o wide

kl apply -k ./metrics/grafana/httproute/
kl -n grafana get httproute grafana
kl -n grafana describe httproute grafana

kl label ns --overwrite grafana copy-wild-cert=main
kl apply -k ./metrics/kube-prometheus-stack/grafana-ingress-wildcard/
kl -n grafana get ingress

```

# Automatic provisioning

Grafana automatically imports data from configmaps with certain labels:

- Datasources: label `grafana.com/datasource: main`
- Dashboards: label `grafana.com/dashboard: main`

Only the own `grafana` namespace is monitored.
