
# Palworld

References:
- https://github.com/FuzzyStatic/nitrox-server
- https://github.com/SubnauticaNitrox/Nitrox

This is an _alpha_ version if nitrox which is able to work with Subnautica 2.0.

Stability is below average.

The docker image is a derivative of [FuzzyStatic's image](https://github.com/FuzzyStatic/nitrox-server).

# Build

```bash
docker_username=
docker_repo=

docker build ./games/subnautica-nitrox/docker/ -t docker.io/$docker_username/$docker_repo:nitrox-dc90f19
docker push docker.io/$docker_username/$docker_repo:nitrox-dc90f19

# you can test this image on your local machine
subnautica_path=
docker run -p 11000:11000/udp \
  -v $subnautica_path:/subnautica \
  -v ./games/subnautica-nitrox/env/saves:/home/nitrox/.config/Nitrox/saves/docker-save \
  -e SUBNAUTICA_INSTALLATION_PATH=/subnautica \
  docker.io/$docker_username/$docker_repo:nitrox-dc90f19
# make sure that ./games/subnautica-nitrox/env/saves
# have a copy of server.cfg (can be generated from server-template.cfg)
```

# Local environment setup

```bash
mkdir -p ./games/subnautica-nitrox/pvc/env/
 cat << EOF > ./games/subnautica-nitrox/pvc/env/pvc.env
subnautica_class=fast
subnautica_size=15Gi
EOF

mkdir -p ./games/subnautica-nitrox/main-app/env/
 cat << EOF > ./games/subnautica-nitrox/main-app/env/passwords.env
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
server_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
 cat << EOF > ./games/subnautica-nitrox/main-app/env/nitrox.env
# leave empty for random seed
seed=
# cache all assets at startup to reduce lags during chunk loading
enable_startup_cache=false
# Possible values: SURVIVAL, FREEDOM, HARDCORE, CREATIVE
game_mode=SURVIVAL
EOF
```

# Deploy

```bash
kl create ns nitrox
kl label ns nitrox pod-security.kubernetes.io/enforce=baseline

kl apply -k ./games/subnautica-nitrox/loadbalancer/
kl -n nitrox get svc

kl apply -k ./games/subnautica-nitrox/pvc/
kl -n nitrox get pvc

# after creating subnautica PVC
# copy your installation folder to that PVC
# root of the PVC must contain Subnautica_Data and Subnautica.exe
# you need to manually edit /Subnautica/Subnautica_Data/StreamingAssets/aa/catalog.json
# replace all \\ with /

# for example, you can copy files from local disk like this:
kl apply -n nitrox -f ./games/subnautica-nitrox/file-transfer.yaml
kl -n nitrox get pod -o wide
subnautica_path=
kl -n nitrox cp "$subnautica_path" file-transfer:/subnautica
kl -n nitrox delete -f ./games/subnautica-nitrox/file-transfer.yaml

kl apply -k ./games/subnautica-nitrox/main-app/
kl -n nitrox get pod -o wide
kl -n nitrox logs sts/nitrox
```

# Cleanup

```bash
kl delete -k ./games/subnautica-nitrox/main-app/
kl delete -k ./games/subnautica-nitrox/loadbalancer/
kl delete -k ./games/subnautica-nitrox/pvc/
kl delete ns nitrox
```
