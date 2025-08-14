
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./docs/backup/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]*/\"version\": 0/' ./docs/backup/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./docs/backup/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./docs/backup/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./docs/backup/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./docs/backup/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./docs/backup/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./docs/backup/dashboards/*.json

kl apply -k ./docs/backup/dashboards/

```

# Cleanup

```bash
kl delete -k ./docs/backup/dashboards/
```
