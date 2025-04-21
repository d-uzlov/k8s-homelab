
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/ephemeral-storage/dashboards/*.json
 sed -i '/\"version\":/d' ./metrics/ephemeral-storage/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/ephemeral-storage/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/ephemeral-storage/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/ephemeral-storage/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/ephemeral-storage/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/ephemeral-storage/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./metrics/ephemeral-storage/dashboards/*.json

kl apply -k ./metrics/ephemeral-storage/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/ephemeral-storage/dashboards/
```
