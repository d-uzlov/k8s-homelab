
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./storage/minio/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./storage/minio/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./storage/minio/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./storage/minio/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./storage/minio/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./storage/minio/dashboards/*.json

kl apply -k ./storage/minio/dashboards/

```

# Cleanup

```bash
kl delete -k ./storage/minio/dashboards/
```
