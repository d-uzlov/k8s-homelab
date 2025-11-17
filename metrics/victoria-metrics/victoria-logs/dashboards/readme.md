
# Dashboards

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*\",/  \"refresh\": \"360d\",/' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/victoria-metrics/victoria-logs/dashboards/*.json

kl apply -k ./metrics/victoria-metrics/victoria-logs/dashboards/

```

# Dashboards cleanup

```bash
kl delete -k ./metrics/victoria-metrics/victoria-logs/dashboards/
```

# Issues

- Filesystem metrics are useless: https://github.com/google/cadvisor/issues/3588
