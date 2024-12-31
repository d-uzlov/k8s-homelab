
# node-exporter in k8s

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community/prometheus-node-exporter --versions --devel | head
helm show values prometheus-community/prometheus-node-exporter --version 4.43.0 > ./metrics/node-exporter/default-values.yaml
```

```bash
helm template \
  kps \
  prometheus-community/prometheus-node-exporter \
  --version 4.43.0 \
  --values ./metrics/node-exporter/values.yaml \
  | sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '/^ *$/d' \
    -e '\|httpHeaders\:$|d' \
  > ./metrics/node-exporter/nodeExporter.gen.yaml
```

# Deploy

```bash

kl create ns node-exporter
# node exporter needs access to host network, host processes, host settings to work properly
kl label ns node-exporter pod-security.kubernetes.io/enforce=privileged

kl apply -k ./metrics/node-exporter/
kl -n node-exporter get pod -o wide
kl -n node-exporter get servicemonitor

kl apply -k ./metrics/node-exporter/dashboards/ --server-side
```

# Cleanup

```bash
kl delete -k ./metrics/node-exporter/node-exporter/dashboards/
kl delete -k ./metrics/node-exporter/node-exporter/
kl delete ns node-exporter
```

# Updating dashboards

```bash
# remove min interval settings from all panels to force them to use the default data source min interval
# be careful: some panels need bigger interval to work properly
sed -i '/\"interval\":/d' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json
# remove id to avoid collisions
sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json
# set dashboard refresh interval to auto
sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json
```

# Manual metric checking

```bash
bearer=$(kl -n kps exec sts/prometheus-kps -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

kl -n node-exporter describe svc node-exporter
kl get node -o wide
curl -sS -k -H "Authorization: Bearer $bearer" http://$nodeIp:9100/metrics > ./node-exporter-$nodeIp.log
```
