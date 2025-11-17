
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./ingress/cert-manager/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./ingress/cert-manager/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./ingress/cert-manager/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./ingress/cert-manager/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./ingress/cert-manager/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./ingress/cert-manager/dashboards/*.json

kl apply -k ./ingress/cert-manager/dashboards/

```

# Cleanup

```bash
kl delete -k ./ingress/cert-manager/dashboards/
```
