
References:
- https://github.com/prometheus-community/windows_exporter

Config:

```yaml
collectors:
  enabled: cache,cpu,cpu_info,container,diskdrive,gpu,hyperv,license,logical_disk,memory,net,os,pagefile,physical_disk,smb,smbclient,system,time,update
log:
  level: info
```

```bash

mkdir -p ./metrics/node-exporter/windows/env/

cat << EOF > ./metrics/node-exporter/windows/env/scrape-windows-exporter.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-windows-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: windows-exporter
      cluster_type: workstation
      cluster: my-cluster
    targets:
    - workstation.example.com:9182
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    sourceLabels: [ instance ]
    regex: (.*):9182
    action: replace
  - action: drop
    sourceLabels: [ __name__ ]
    regex: go_.*|process_.*|promhttp_.*|windows_hyperv_virtual_network_adapter_drop_reasons
EOF

```

# Manual metric checking

```bash

# ip or domain name
node=workstation.example.com
curl -sS --insecure http://$node:9182/metrics > ./windows-exporter.log

```
