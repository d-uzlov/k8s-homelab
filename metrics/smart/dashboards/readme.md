
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./metrics/smart/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./metrics/smart/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/smart/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./metrics/smart/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./metrics/smart/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./metrics/smart/dashboards/*.json

kl apply -k ./metrics/smart/dashboards/

```

# Cleanup

```bash
kl delete -k ./metrics/smart/dashboards/
```

# References

- Source of smartctl dashboard: https://github.com/blesswinsamuel/grafana-dashboards/tree/main
