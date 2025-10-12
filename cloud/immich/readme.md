
# Immich

References:
- https://immich.app/docs/install/kubernetes
- https://github.com/immich-app/immich-charts/blob/main/README.md
- https://meichthys.github.io/foss_photo_libraries/
- https://github.com/tensorchord/cloudnative-vectorchord/pkgs/container/cloudnative-vectorchord

# Upgrades

References:
- https://github.com/immich-app/immich/releases
- https://github.com/immich-app/immich/discussions?discussions_q=label%3Achangelog%3Abreaking-change+sort%3Adate_created

**Note**: Immich sometimes makes breaking changes in the config.
Always check out the discussions or release notes before changing the container image version.

# Local config

```bash

mkdir -p ./cloud/immich/pvc/env/

cp ./cloud/immich/pvc/user-data.template.yaml ./cloud/immich/pvc/env/user-data.yaml
cp ./cloud/immich/pvc/ml-cache.template.yaml ./cloud/immich/pvc/env/ml-cache.yaml

mkdir -p ./cloud/immich/dragonfly/env/

 cat << EOF > ./cloud/immich/dragonfly/env/password.env
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

kl get sc
storage_class=
sed "s/storageClassName: REPLACE_ME/storageClassName: $storage_class/" ./cloud/immich/dragonfly/dragonfly-immich.template.yaml > ./cloud/immich/dragonfly/env/dragonfly-immich.yaml

mkdir -p ./cloud/immich/main-app/env/

# example:
# location_tag=vps/k8s/clusterName
location_tag=
# a friendly name for immich deployment
immichClusterName=

 cat << EOF > ./cloud/immich/main-app/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $location_tag
    action: replace
EOF

 cat << EOF > ./cloud/immich/main-app/env/patch-immich-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: immich_cluster
    replacement: $immichClusterName
    action: replace
EOF

```

# Deploy

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

```bash

kl create ns immich
kl label ns immich pod-security.kubernetes.io/enforce=baseline

kl apply -k ./cloud/immich/dragonfly/
kl -n immich get dragonfly
kl -n immich get pod -o wide -L role
kl -n immich get pvc
kl -n immich get svc

kl apply -f ./cloud/immich/pvc/env/user-data.yaml
kl apply -f ./cloud/immich/pvc/env/ml-cache.yaml
kl -n immich get pvc

kl apply -k ./cloud/immich/immich-route-private/
kl -n immich get htr

kl apply -k ./cloud/immich/main-app/
kl -n immich get pod -o wide

# by default httproute is private because in the initial setup you create the admin user
# after initial setup you can safely make it public
kl apply -k ./cloud/immich/immich-route/
kl -n immich get httproute

```

# Cleanup

```bash
kl delete -k ./cloud/immich/main-app/
kl delete -k ./cloud/immich/pvc/
kl delete -k ./cloud/immich/postgres/
kl delete ns immich
```

# Settings

Smart search:
- default: ViT-B-32__openai
- best? (multi-lang):
- - XLM-Roberta-Large-ViT-H-14__frozen_laion5b_s13b_b90k
- - XLM-Roberta-Large-Vit-B-16Plus

References:
- https://github.com/immich-app/immich/discussions/11830#discussioncomment-10351544
- https://github.com/immich-app/immich/discussions/11862
- https://www.reddit.com/r/immich/comments/1gph4ay/how_to_pick_a_multilingual_ml_model_for_immich/

# OIDC setup

References:
- https://immich.app/docs/administration/oauth/
- https://docs.goauthentik.io/integrations/services/immich/

Setup actions:

- Create OIDC client
- Add allowed redirect URIs (change `immich.example.com` to your ingress domain):
- - https://immich.example.com/auth/login
- - https://immich.example.com/user-settings
- - `app.immich:///oauth-callback` (required for the immich mobile app)
- Create `immich` application linked to this provider
- Go to settings in Immich web UI: `Administration -> Authentication Settings -> OAuth`
- Set `Issuer URL` to value from Provider (open provider details to see it)
- Set `Client ID` to value from Provider
- Set `Client Secret` to value from Provider (click `edit` to see it)
- Don't forget to click the `Save` button

# Merge classic and OAuth users

`Account Settings -> OAuth -> Link to OAuth`

Accounts are linked based on email match.
Match should be exact, including case.

# metrics

References:
- https://github.com/eithan1231/immich-exporter

```bash

mkdir -p ./cloud/immich/metrics/env/

# example:
# location_tag=vps/k8s/clusterName
location_tag=
# a friendly name for immich deployment
immichClusterName=

 cat << EOF > ./cloud/immich/main-app/env/patch-location-tag.yaml
- op: add
  path: /spec/relabelings/0
  value:
    targetLabel: location
    replacement: $location_tag
    action: replace
EOF

 cat << EOF > ./cloud/immich/main-app/env/patch-immich-cluster-tag.yaml
- op: add
  path: /spec/relabelings/0
  value:
    targetLabel: immich_cluster
    replacement: $immichClusterName
    action: replace
EOF

# generate an API key for the exporter

 cat << EOF > ./cloud/immich/metrics/env/api-key.env
api-key=
EOF

kl apply -k ./cloud/immich/metrics/
kl -n immich get pod -o wide

```
