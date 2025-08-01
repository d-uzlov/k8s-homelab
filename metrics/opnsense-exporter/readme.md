
# opnsense-exporter

References:
- https://github.com/AthennaMind/opnsense-exporter

# Deploy

```bash

mkdir -p ./metrics/opnsense-exporter/env/

cat << EOF > ./metrics/opnsense-exporter/env/config.env
address=opnsense.example.com
# https://docs.opnsense.org/development/how-tos/api.html#creating-keys
key=w86XNZob/8Oq8aC5r0kbNarNtdpoQU781fyoeaOBQsBwkXUt
secret=XeD26XVrJ5ilAc/EmglCRC+0j2e57tRsjHwFepOseySWLM53pJASeTA3
instance_name=qwe
EOF

kl create ns opnsense-exporter
kl label ns opnsense-exporter pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/opnsense-exporter/
kl -n opnsense-exporter get pod -o wide

kl apply -k ./metrics/opnsense-exporter/dashboards/ --server-side

```

# Cleanup

```bash
kl delete -k ./metrics/opnsense-exporter/
kl delete ns opnsense-exporter
```

# Manual metric checking

```bash
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://opnsense-exporter.opnsense-exporter:80/metrics > ./opnsense-exporter.log
```

# Prometheus scrape config

```bash

 cat << EOF > ./metrics/opnsense-exporter/env/scrape-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: opnsense-exporter
  namespace: opnsense-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: opnsense
      cluster_type: site
      cluster: my-cluster
    targets:
    - opnsense-exporter.opnsense-exporter
  metricRelabelings:
  - action: labeldrop
    regex: instance
EOF

kl apply -f ./metrics/opnsense-exporter/env/scrape-patch.yaml

```
