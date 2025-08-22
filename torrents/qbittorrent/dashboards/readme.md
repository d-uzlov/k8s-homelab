
# Deploy

```bash

 # force all panels to use the default data source min interval
 sed -i '/\"interval\":/d' ./torrents/qbittorrent/dashboards/*.json
 sed -i 's/\"version\"\: [0-9]+/\"version\": 0/' ./torrents/qbittorrent/dashboards/*.json
 sed -i '/\"pluginVersion\":/d' ./torrents/qbittorrent/dashboards/*.json
 # avoid id collisions
 sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./torrents/qbittorrent/dashboards/*.json
 sed -i 's/^  \"refresh\": \".*[sm]\",/  \"refresh\": \"auto\",/' ./torrents/qbittorrent/dashboards/*.json
 # remove local variable values
 sed -i '/        \"current\": {/,/        }\,/d' ./torrents/qbittorrent/dashboards/*.json
 sed -i 's/^  \"timezone\": \".*\",/  \"timezone\": \"browser\",/' ./torrents/qbittorrent/dashboards/*.json
 # grafana likes to flip some values between {"color":"green","value": null} and {"color":"green"}
 # this forces them all to lose "value": null, so that there are less changes in commits
 sed -i -z -r 's/,\n *\"value\": null(\n *})/\1/g' ./torrents/qbittorrent/dashboards/*.json

kl apply -k ./torrents/qbittorrent/dashboards/

```

# Cleanup

```bash
kl delete -k ./torrents/qbittorrent/dashboards/
```
