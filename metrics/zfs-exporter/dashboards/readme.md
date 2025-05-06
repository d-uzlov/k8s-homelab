
# Deploy

```bash

kl apply -k ./metrics/zfs-exporter/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/dashboards/
```

# Updating dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/zfs-exporter/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]*/\"version\": 0/' ./metrics/zfs-exporter/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/zfs-exporter/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/zfs-exporter/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/zfs-exporter/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/zfs-exporter/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/zfs-exporter/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./metrics/zfs-exporter/dashboards/*.json

```
