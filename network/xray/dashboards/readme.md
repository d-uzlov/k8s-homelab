
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./network/xray/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./network/xray/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./network/xray/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./network/xray/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {\\n/,/        }\,/d' ./network/xray/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./network/xray/dashboards/*.json

kl apply -k ./network/xray/dashboards/

```

# Cleanup

```bash
kl delete -k ./network/xray/dashboards/
```
