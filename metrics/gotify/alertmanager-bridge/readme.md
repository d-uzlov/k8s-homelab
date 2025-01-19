
# gotify

References:
- https://github.com/DRuggeri/alertmanager_gotify_bridge
- https://ghcr.io/druggeri/alertmanager_gotify_bridge
- https://github.com/prometheus/alertmanager/issues/2120

# Deploy

```bash

mkdir -p ./metrics/gotify/alertmanager-bridge/env/
 cat << EOF > ./metrics/gotify/alertmanager-bridge/env/token.env
# create token in gotify GUI
token=
EOF

kl apply -k ./metrics/gotify/alertmanager-bridge/
kl -n gotify get pod -o wide -L spilo-role

```

# Cleanup

```bash
kl delete -k ./metrics/gotify/alertmanager-bridge/
```

# TODO

- add templates
- maybe move to alertmanager?
