
# Dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/cadvisor/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/cadvisor/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/cadvisor/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/cadvisor/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/cadvisor/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/cadvisor/dashboards/*.json

kl apply -k ./metrics/cadvisor/dashboards/

```

# Dashboards cleanup

```bash
kl delete -k ./metrics/cadvisor/dashboards/
```

# Issues

- Filesystem metrics are useless: https://github.com/google/cadvisor/issues/3588
