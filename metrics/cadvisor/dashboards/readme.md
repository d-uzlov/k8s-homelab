
# Dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/cadvisor/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]*/\"version\": 0/' ./metrics/cadvisor/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/cadvisor/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/cadvisor/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/cadvisor/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/cadvisor/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/cadvisor/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./metrics/cadvisor/dashboards/*.json

kl apply -k ./metrics/cadvisor/dashboards/ --server-side

```

# Dashboards cleanup

```bash
kl delete -k ./metrics/cadvisor/dashboards/
```

# Issues

- Filesystem metrics are useless: https://github.com/google/cadvisor/issues/3588
