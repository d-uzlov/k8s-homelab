
# dex

References:
- https://github.com/dexidp/dex
- https://dexidp.io/docs/getting-started/
- https://github.com/dexidp/dex/pkgs/container/dex
- https://charts.dexidp.io/

# generate config

You only need to do this when updating the app.

```bash
helm repo add dex https://charts.dexidp.io
helm repo update dex
helm search repo dex/dex --versions --devel | head
helm show values dex/dex --version 0.24.0 > ./auth/dex/default-values.yaml
```

```bash

helm template \
  dex \
  dex/dex \
  --version 0.24.0 \
  --namespace auth-dex \
  --values ./auth/dex/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/dex/dex.gen.yaml

```

# config

```bash

[ -f ./auth/dex/env/dex-config.yaml ] || wget https://github.com/dexidp/dex/raw/refs/heads/master/config.yaml.dist -O ./auth/dex/env/dex-config.yaml

```

See comments in the config file for documentation.

# Deploy

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

Generate passwords and set up config.

```bash

mkdir -p ./auth/dex/config/env/
 cat << EOF > ./auth/dex/config/env/master_key.env
master_key=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

```

```bash

kl create ns auth-dex
kl label ns auth-dex pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/dex/httproute-private/
kl -n auth-dex get htr

kl apply -k ./auth/dex/
kl -n auth-dex get pod -o wide

ingress_address=$(kl -n auth-dex get httproute dex-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
# show discovery info
curl "https://$ingress_address/.well-known/openid-configuration" | jq

# after you finished the initial set up process, it's safe to open public access to dex
kl apply -k ./auth/dex/httproute-public/
kl -n auth-dex get httproute

# now go to ./auth/dex/env/app.conf and change origin parameter

```

# Cleanup

```bash
kl delete -k ./auth/dex/
kl delete ns dex
```

# clients

```bash

# generate new client secret
openssl rand -hex 20

```
