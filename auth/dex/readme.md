
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

wget https://github.com/dexidp/dex/raw/refs/tags/v2.44.0/config.yaml.dist -O ./auth/dex/dex-config-sample.yaml

```

# config

```bash

[ -f ./auth/dex/env/dex-config.yaml ] || cp ./auth/dex/dex-config-sample.yaml ./auth/dex/env/dex-config.yaml

```

See comments in the sample config file for documentation.

# Deploy

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

```bash

kl create ns auth-dex
kl label ns auth-dex pod-security.kubernetes.io/enforce=baseline

# as OIDC issuer, Dex needs a single URL that clients will access
# if you want to deploy it as private issuer, and then switch to public,
# don't forget to update all references
kl apply -k ./auth/dex/httproute-private/
kl apply -k ./auth/dex/httproute-public/
kl -n auth-dex get htr

kl apply -k ./auth/dex/
kl -n auth-dex get pod -o wide

ingress_address=$(kl -n auth-dex get httproute dex-public -o go-template --template "{{ (index .spec.hostnames 0)}}")
# show discovery info
curl "https://$ingress_address/.well-known/openid-configuration" | jq
# show issuer url
curl "https://$ingress_address/.well-known/openid-configuration" | jq .issuer -r

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

Dex developers don't want to add good UX.
So you will need to add every redirect URL manually,
and then redeploy Dex to apply changes.

References:
- https://github.com/dexidp/dex/issues/448
- https://github.com/dexidp/dex/pull/3771
