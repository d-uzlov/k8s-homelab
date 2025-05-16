
# Zitadel

Current version seems to have a memory leak.

References:
- https://github.com/zitadel/zitadel
- https://zitadel.com/docs/self-hosting/deploy/kubernetes

# Generate config

You only need to do this when updating the app.

```bash
helm repo add zitadel https://charts.zitadel.com
helm repo update zitadel
helm search repo zitadel/zitadel --versions --devel | head
helm show values zitadel/zitadel --version 8.13.1 > ./auth/zitadel/default-values.yaml
```

```bash
# https://hub.docker.com/r/bitnamicharts/redis/tags
# helm show values oci://registry-1.docker.io/bitnamicharts/redis --version 20.6.2 > ./auth/authentik/redis-default-values.yaml

helm template \
  zitadel \
  zitadel/zitadel \
  --version 8.13.1 \
  --namespace zitadel \
  --values ./auth/zitadel/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/zitadel/zitadel.gen.yaml

```

# Deploy

Generate passwords and set up config.

```bash

# ======== Postgres setup ========

mkdir -p ./auth/zitadel/postgres-cnpg/env/

storage_class=
storage_size=1Gi
s3_server_address=http://nas.example.com:9000/
# make sure that bucket path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
s3_bucket_path=s3://postgres-test/subfolder/

 cat << EOF > ./auth/zitadel/postgres-cnpg/env/backup-s3-credentials.env
key=dmzER5pleUdusVaG9n8d
secret=zD07Jfk483DAJU8soRLZ4x9xdbtsU1QPcnU2eCp7
EOF

 cat << EOF > ./auth/zitadel/postgres-cnpg/env/patch.env
---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres
spec:
  instances: 2
  storage:
    size: $storage_size
    storageClass: $storage_class
  backup:
    barmanObjectStore:
      endpointURL: $s3_server_address
      destinationPath: $s3_bucket_path
EOF

mkdir -p ./auth/zitadel/config/env/
 cat << EOF > ./auth/zitadel/config/env/master_key.env
master_key=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

```

```bash

kl create ns zitadel
kl label ns zitadel pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/zitadel/postgres-cnpg/

kl -n zitadel get cluster
kl -n zitadel describe cluster cnpg
kl -n zitadel get pvc
kl -n zitadel get pods -o wide -L role -L cnpg.io/jobRole
kl -n zitadel get svc
kl -n zitadel get secrets
kl cnpg -n zitadel status cnpg

# show connection secret contents
kl -n zitadel get secret cnpg-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'
kl -n zitadel get secret cnpg-superuser -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

kl apply -k ./auth/zitadel/init/
kl -n zitadel get pod -o wide
kl -n zitadel logs jobs/init
kl -n zitadel wait --for condition=complete job/init --timeout=30s
kl -n zitadel describe job init
kl -n zitadel delete job init

kl apply -k ./auth/zitadel/httproute-private/
kl -n zitadel get httproute
kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}"

kl apply -k ./auth/zitadel/setup/
kl -n zitadel get pod -o wide
kl -n zitadel logs jobs/setup
kl -n zitadel wait --for condition=complete job/setup --timeout=30s
kl -n zitadel describe job setup
kl -n zitadel delete job setup

kl apply -k ./auth/zitadel/
kl -n zitadel get pod -o wide
kl -n zitadel logs deployments/zitadel

# go here to set up access
echo "https://"$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/if/flow/initial-setup/
# after you finished the initial set up process, it's safe to open public access to zitadel
kl apply -k ./auth/zitadel/httproute-public/
kl -n zitadel get httproute

# print default user login
echo "zitadel-admin@zitadel.$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")"

# zitadel has single issuer URL for all projects/apps
# print issuer URL
echo https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
# print discovery URL
echo https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration
curl https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration | jq

```

Don't forget to enable `Projects -> your_project -> your_application -> Grant Types -> Refresh Token`.

# Cleanup

```bash
kl -n zitadel delete job init
kl -n zitadel delete job setup
kl delete -k ./auth/zitadel/
kl delete -k ./auth/zitadel/postgres-cnpg/
kl delete ns zitadel
```

# Debugging

```bash

# if you are getting Errors.IAM.NotFound
# check the list of active domains in the database
kl cnpg -n zitadel psql cnpg app << EOF
SELECT * FROM eventstore.fields
WHERE object_type = 'instance_domain'
AND field_name = 'domain';
EOF

```
