
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/component-monitoring/xray/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/component-monitoring/xray/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/xray/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/xray/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {\\n/,/        }\,/d' ./metrics/component-monitoring/xray/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/component-monitoring/xray/dashboards/*.json

kl apply -k ./metrics/component-monitoring/xray/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/component-monitoring/xray/dashboards/
```
