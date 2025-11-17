
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/zfs-exporter/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/zfs-exporter/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/zfs-exporter/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/zfs-exporter/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/zfs-exporter/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/zfs-exporter/dashboards/*.json

kl apply -k ./metrics/zfs-exporter/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/dashboards/
```
