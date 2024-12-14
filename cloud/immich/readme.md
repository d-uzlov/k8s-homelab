
# Immich

References:
- https://immich.app/docs/install/kubernetes
- https://github.com/immich-app/immich-charts/blob/main/README.md
- https://meichthys.github.io/foss_photo_libraries/

# Upgrades

References:
- https://github.com/immich-app/immich/releases
- https://github.com/immich-app/immich/discussions?discussions_q=label%3Achangelog%3Abreaking-change+sort%3Adate_created

**Note**: Immich sometimes makes breaking changes in the config.
Always check out the discussions or release notes before changing the container image version.

# Helm config

Immich has simple deployment.
I used helm deployment as an example, and to set up postgres,
but the main app deployment is managed manually.

```bash
helm repo add immich https://immich-app.github.io/immich-charts
helm repo update immich
helm search repo immich/immich --versions --devel | head
helm show values immich/immich --version 0.8.5 > ./cloud/immich/default-values.yaml
```

```bash
helm template \
  immich \
  immich/immich \
  --version 0.8.5 \
  --values ./cloud/immich/values.yaml \
  --namespace immich \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|^#|d' \
  > ./cloud/immich/deployment.gen.yaml
```

# Local config

```bash
mkdir -p ./cloud/immich/pvc/env/
cat <<EOF > ./cloud/immich/pvc/env/pvc.env
# userdata uses ReadWriteMany type volumes
userdata_sc=fast
userdata_size=1Ti
EOF

mkdir -p ./cloud/immich/postgres/env/
mkdir -p ./cloud/immich/main-app/env/
tee << EOF ./cloud/immich/postgres/env/passwords.env ./cloud/immich/main-app/env/passwords.env > /dev/null
postgres-password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

postgresStorageClass=
sed -e "s/STORAGE_CLASS/$postgresStorageClass/" \
  ./cloud/immich/postgres/patch-template.yaml \
  > ./cloud/immich/postgres/env/patch.yaml

```

# Deploy

```bash
kl create ns immich
kl label ns immich pod-security.kubernetes.io/enforce=baseline

# wildcard ingress
kl label ns --overwrite onlyoffice copy-wild-cert=main
kl apply -k ./cloud/onlyoffice/ingress-wildcard/
kl -n onlyoffice get ingress

kl apply -k ./cloud/immich/postgres/
kl -n immich get pvc
kl -n immich get pod -o wide

kl apply -k ./cloud/immich/pvc/
kl -n immich get pvc

kl apply -k ./cloud/immich/immich-route-private/
kl -n immich get httproute

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
- best? (multi-lang): XLM-Roberta-Large-ViT-H-14__frozen_laion5b_s13b_b90k ?? XLM-Roberta-Large-Vit-B-16Plus
