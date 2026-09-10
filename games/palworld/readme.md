
# Palworld

References:
- https://store.steampowered.com/app/1623730/Palworld/
- https://github.com/thijsvanloef/palworld-server-docker
- https://hub.docker.com/r/thijsvanloef/palworld-server-docker

# Local environment setup

```bash

mkdir -p ./games/palworld/main-app/env/

 cat << EOF > ./games/palworld/main-app/env/patch.yaml
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: immich-postgresql
  namespace: immich
spec:
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: tulip-nvmeof
      resources:
        requests:
          storage: 2Gi
EOF

 cat << EOF > ./games/palworld/main-app/env/passwords.env
server_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF

 cat << EOF > ./games/palworld/main-app/env/settings.env
# set to true to add your serve to the list of community servers
# don't forget to set a secure password
use_community=false
server_name=Put your server name here
server_description=Put your description here
# has to be enabled on first start, but can be disabled on consequent restarts
autoupdate=true
friendly_fire=true
max_base_workers=30
max_bases=10
# One of: None,Item,ItemAndEquipment,All
death_penalty=None
drop_items_timeout_hours=3
pal_spawn_rate=2.0
pal_capture_rate=1.0
exp_rate=0.3
hunger_rate=1.0
supply_drop_minutes=30
enemy_drop_item_rate=1.0
EOF

```

# Deploy

```bash

kl create ns palworld
# conflicts with NET_RAW capability
# kl label ns palworld pod-security.kubernetes.io/enforce=baseline

# kl apply -k ./games/palworld/pvc/

kl apply -k ./games/palworld/loadbalancer/
kl -n palworld get svc

kl apply -k ./games/palworld/main-app/
kl -n palworld get pvc
kl -n palworld get pod -o wide

kl -n palworld logs pods/palworld-0 --tail 50 --follow

kl -n palworld exec pods/palworld-0 -- rcon-cli save
kl -n palworld exec pods/palworld-0 -- backup
# this will stop the server, restore the backup and shutdown the container, expecting orchestrator to restart it
kl -n palworld exec pods/palworld-0 -it -- restore

```

# Cleanup

```bash
kl delete -k ./games/palworld/main-app/
kl delete -k ./games/palworld/loadbalancer/
kl delete ns palworld
```
