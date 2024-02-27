
# Palworld

References:
- https://store.steampowered.com/app/1623730/Palworld/
- https://github.com/thijsvanloef/palworld-server-docker

# Local environment setup

```bash
mkdir -p ./games/palworld/pvc/env/
cat << EOF > ./games/palworld/pvc/env/pvc.env
data_class=fast
data_size=15Gi
EOF

mkdir -p ./games/palworld/main-app/env/
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
# One of: None,Normal,Difficult
difficulty=Normal
friendly_fire=true
# this one doesn't seems to work
max_base_workers=20
# One of: None,Item,ItemAndEquipment,All
death_penalty=All
drop_items_timeout_hours=1
EOF
```

# Deploy

```bash
kl create ns palworld
kl label ns palworld pod-security.kubernetes.io/enforce=baseline

kl apply -k ./games/palworld/pvc/
kl -n palworld get pvc

kl apply -k ./games/palworld/loadbalancer/
kl -n palworld get svc

kl apply -k ./games/palworld/main-app/

kl -n palworld get pod -o wide

kl -n palworld logs deployments/palworld
```

# Cleanup

```bash
kl delete -k ./games/palworld/main-app/
kl delete -k ./games/palworld/loadbalancer/
kl delete -k ./games/palworld/pvc/
kl delete ns palworld
```
