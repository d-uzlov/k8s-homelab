
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
  node-exporter \
  prometheus-community/prometheus-node-exporter \
  --version 4.43.0 \
  --values ./metrics/node-exporter/values.yaml \
  --namespace node-exporter \
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

# Local config setup

```bash

mkdir -p ./metrics/node-exporter/env/
clusterName=
 cat << EOF > ./metrics/node-exporter/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/-
  value:
    targetLabel: cluster
    replacement: $clusterName
EOF

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
kl delete -k ./metrics/node-exporter/dashboards/
kl delete -k ./metrics/node-exporter/node-exporter/
kl delete ns node-exporter
```

# Updating dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/node-exporter/dashboards/*.json
 sed -i '/\"version\":/d' ./metrics/node-exporter/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/node-exporter/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/node-exporter/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/node-exporter/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/node-exporter/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/node-exporter/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./metrics/node-exporter/dashboards/*.json

```

# Manual metric checking

```bash
kl -n node-exporter describe svc node-exporter

# pick some node randomly
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS --insecure http://node-exporter.node-exporter:9100/metrics > ./node-exporter.log
```

# ZFS stats

Metric explanation:
- `nread` and `nwrite` are read/write bytes.
- `reads` and `writes` are number of read/write operations.
- Source: https://utcc.utoronto.ca/~cks/space/blog/linux/ZFSPerDatasetStats

ZFS IO stats are mostly removed from node-exporter:
- https://github.com/prometheus/node_exporter/issues/2068

Additional stats are gathered here:
- [zfs-exporter-pdf](../zfs-exporter/pdf/readme.md)
- [zfs-exporter-chris](../zfs-exporter/chris-siebenmann/readme.md)
