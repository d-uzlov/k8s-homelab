
# Updating dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/component-monitoring/k8s-control-plane/dashboards/*.json

kl apply -k ./metrics/component-monitoring/k8s-control-plane/dashboards/

```
