
# Metrics for disk SMART parameters

References:
- https://github.com/prometheus-community/smartctl_exporter

# Deploy

```bash

kl apply -f ./metrics/smart/alert.yaml

# update database for smartctl from apt
sudo /usr/sbin/update-smart-drivedb
# update database for smartctl from 'make install'
sudo /usr/local/sbin/update-smart-drivedb

```

# Windows setup

Download the binary here:
- https://github.com/d-uzlov/smartctl_exporter/releases/download/1.14.0-device-id/smartctl_exporter-win64.exe

```powershell

# adjust for your binary path
nssm install smartctl_exporter c:\Users\user\programs\smartctl_exporter-win64.exe --smartctl.path=smartctl --smartctl.interval=60s --smartctl.rescan=10m --smartctl.device-include=".*" --smartctl.powermode-check="standby" --web.listen-address=:9633 --log.level=info --log.format=logfmt

nssm edit smartctl_exporter

```

Ensure the following argument is present in the edit window: `"--smartctl.path=c:\Program Files\smartmontools\bin\smartctl.exe"`

# TODO

Investigate Seagate read error rate:
- https://github.com/smartmontools/smartmontools/issues/220
- https://serverfault.com/questions/313649/how-to-interpret-this-smartctl-smartmon-data

# Harvesting additional metrics from disk attributes

Some devices don't have proper reporting, but do have nonstandard device-specific attributes.
`smartctl` doesn't seem too eager to add new devices into database,
but you can write recording rules that will extract data from attributes.

For example, this rule creates `smartctl_device_bytes_written` metric for Seagate drives.

```bash

 cat << EOF > ./metrics/smart/env/record-attributes.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: record-smartctl-attribute-mining
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  groups:
  - name: record-smartctl-attribute-mining
    rules:
    - record: mined:smartctl_device_bytes_written
      expr: |-
        smartctl_device_bytes_written
    - record: mined:smartctl_device_bytes_read
      expr: |-
        smartctl_device_bytes_read
    # lba==lba: Seagate, Apacer, etc.
    - record: mined:smartctl_device_bytes_written
      expr: |-
        max without (attribute_name, attribute_value_type, attribute_id, attribute_flags_long, attribute_flags_short) (
          smartctl_device_attribute{device=~"ST12000NM.*|Apacer AS340.*", attribute_name="Total_LBAs_Written", attribute_value_type="raw"}
          unless on(instance, device)
          smartctl_device_bytes_written
        )
        * max without(blocks_type) (smartctl_device_block_size{blocks_type="logical"})
    - record: mined:smartctl_device_bytes_read
      expr: |-
        max without (attribute_name, attribute_value_type, attribute_id, attribute_flags_long, attribute_flags_short) (
          smartctl_device_attribute{device=~"ST12000NM.*", attribute_name="Total_LBAs_Read", attribute_value_type="raw"}
          unless on(instance, device)
          smartctl_device_bytes_read
        )
        * max without(blocks_type) (smartctl_device_block_size{blocks_type="logical"})
EOF

kl apply -f ./metrics/smart/env/record-attributes.yaml

```
