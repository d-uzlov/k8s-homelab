
# Deploy

```bash

kl apply -k ./metrics/node-exporter/dashboards/ --server-side

```

# Cleanup

```bash
kl delete -k ./metrics/node-exporter/dashboards/
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
