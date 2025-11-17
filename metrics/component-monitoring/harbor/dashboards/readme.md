
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/component-monitoring/harbor/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/component-monitoring/harbor/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/harbor/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/harbor/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/component-monitoring/harbor/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/component-monitoring/harbor/dashboards/*.json

kl apply -k ./metrics/component-monitoring/harbor/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/component-monitoring/harbor/dashboards/
```
