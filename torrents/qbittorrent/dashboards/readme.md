
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./torrents/qbittorrent/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./torrents/qbittorrent/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./torrents/qbittorrent/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./torrents/qbittorrent/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./torrents/qbittorrent/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./torrents/qbittorrent/dashboards/*.json

kl apply -k ./torrents/qbittorrent/dashboards/

```

# Cleanup

```bash
kl delete -k ./torrents/qbittorrent/dashboards/
```
