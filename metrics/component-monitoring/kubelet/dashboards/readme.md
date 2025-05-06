
# Dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/component-monitoring/kubelet/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]*/\"version\": 0/' ./metrics/component-monitoring/kubelet/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/component-monitoring/kubelet/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/kubelet/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/kubelet/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/component-monitoring/kubelet/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/component-monitoring/kubelet/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./metrics/component-monitoring/kubelet/dashboards/*.json

kl apply -k ./metrics/component-monitoring/kubelet/dashboards/

```

# Dashboards cleanup

```bash
kl delete -k ./metrics/component-monitoring/kubelet/dashboards/
```

# Issues

- Filesystem metrics are useless: https://github.com/google/cadvisor/issues/3588
