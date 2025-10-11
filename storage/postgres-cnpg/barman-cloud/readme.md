
# barman-cloud plugin for CNPG

References:
- https://cloudnative-pg.io/plugin-barman-cloud/docs/intro/
- https://github.com/cloudnative-pg/plugin-barman-cloud/

# generate config

You only need to do this when updating the app.

```bash

mkdir -p ./storage/postgres-cnpg/barman-cloud/env/

wget https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.7.0/manifest.yaml \
  -O ./storage/postgres-cnpg/barman-cloud/env/barman-cloud-manifest-raw.gen.yaml

yq 'select(.kind == "CustomResourceDefinition")' ./storage/postgres-cnpg/barman-cloud/env/barman-cloud-manifest-raw.gen.yaml > ./storage/postgres-cnpg/barman-cloud/barman-cloud-crd.gen.yaml
yq 'select(.kind != "CustomResourceDefinition" and .kind != "Issuer")' ./storage/postgres-cnpg/barman-cloud/env/barman-cloud-manifest-raw.gen.yaml > ./storage/postgres-cnpg/barman-cloud/barman-cloud.gen.yaml

```

# deploy

```bash

kl apply -f ./storage/postgres-cnpg/barman-cloud/barman-cloud-crd.gen.yaml --server-side --force-conflicts

kl apply -k ./storage/postgres-cnpg/barman-cloud/
kl -n pgo-cnpg get pod -o wide

kl -n pgo-cnpg logs deployments/barman-cloud

```

# cleanup

```bash
kl delete -k ./storage/postgres-cnpg/barman-cloud/
kl delete -f ./storage/postgres-cnpg/barman-cloud/barman-cloud-crd.gen.yaml
```
