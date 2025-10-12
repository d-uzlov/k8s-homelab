
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./cloud/immich/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]+/\"version\": 0/' ./cloud/immich/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./cloud/immich/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./cloud/immich/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./cloud/immich/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./cloud/immich/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./cloud/immich/dashboards/*.json

kl apply -k ./cloud/immich/dashboards/

```

# Cleanup

```bash
kl delete -k ./cloud/immich/dashboards/
```
