
# 3x-ui-exporter

References:
- https://github.com/m4l3vich/3x-ui-prometheus-exporter

# Local config setup

```bash

mkdir -p ./metrics/3x-ui-exporter/env/
clusterName=
 cat << EOF > ./metrics/3x-ui-exporter/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF
 cat << EOF > ./metrics/3x-ui-exporter/env/credentials.env
url=
username=
password=
EOF

```

# Deploy

```bash

kl create ns 3x-ui-exporter
kl label ns 3x-ui-exporter pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/3x-ui-exporter/
kl -n 3x-ui-exporter get pod -o wide

# kl apply -k ./metrics/3x-ui-exporter/dashboards/ --server-side

```

Don't forget to deploy Grafana dashboards:
- [Dashboards](./dashboards/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/3x-ui-exporter/
kl delete ns 3x-ui-exporter
```

# Manual metric checking

```bash

kl -n 3x-ui-exporter describe svc xray-3x-ui-exporter

kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://xray-3x-ui-exporter.3x-ui-exporter/metrics > ./3x-ui-exporter-metrics.log

# check if 3x-ui responds at all
curl -v -k --cookie cookie.txt --cookie-jar cookie.txt -X POST -d 'username=qwe&password=123' https://$3xui_host/login
curl -v -k --cookie cookie.txt --cookie-jar cookie.txt -X POST https://$3xui_host/panel/api/inbounds/onlines

```
