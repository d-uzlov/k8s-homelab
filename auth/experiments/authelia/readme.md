
# Authelia

References:
- https://www.authelia.com/integration/kubernetes/chart/

Authelia needs an LDAP backend.
I didn't find a good LDAP provider with high availability.

# Generate config

You only need to do this when updating the app.

```bash
helm repo add authelia https://charts.authelia.com
helm repo update authelia
helm search repo authelia/authelia --versions --devel | head
helm show values authelia/authelia --version 0.10.10 > ./auth/authelia/default-values.yaml
```

```bash
# https://hub.docker.com/r/bitnamicharts/redis/tags
# helm show values oci://registry-1.docker.io/bitnamicharts/redis --version 20.6.2 > ./auth/authentik/redis-default-values.yaml

helm template \
  authelia \
  authelia/authelia \
  --version 0.10.10 \
  --namespace authelia \
  --values ./auth/authelia/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/authelia/authelia.gen.yaml

```

# Deploy

Generate passwords and set up config.

```bash

# ======== Postgres setup ========

mkdir -p ./auth/authelia/postgres-cnpg/env/

storage_class=
storage_size=1Gi
s3_server_address=http://nas.example.com:9000/
# make sure that bucket path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
s3_bucket_path=s3://postgres-test/subfolder/

 cat << EOF > ./auth/authelia/postgres-cnpg/env/backup-s3-credentials.env
key=dmzER5pleUdusVaG9n8d
secret=zD07Jfk483DAJU8soRLZ4x9xdbtsU1QPcnU2eCp7
EOF

 cat << EOF > ./auth/authelia/postgres-cnpg/env/patch.env
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

mkdir -p ./auth/authelia/config/env/
 cat << EOF > ./auth/authelia/config/env/master_key.env
master_key=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

```

```bash

kl create ns authelia
kl label ns authelia pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/authelia/postgres-cnpg/

kl -n authelia get cluster
kl -n authelia describe cluster cnpg
kl -n authelia get pvc
kl -n authelia get pods -o wide -L role -L cnpg.io/jobRole
kl -n authelia get svc
kl -n authelia get secrets
kl cnpg -n authelia status cnpg

# show connection secret contents
kl -n authelia get secret cnpg-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'
kl -n authelia get secret cnpg-superuser -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

kl apply -k ./auth/authelia/httproute-private/
kl -n authelia get httproute
kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}"

kl apply -k ./auth/authelia/
kl -n authelia get pod -o wide
kl -n authelia logs deployments/authelia

# go here to set up access
echo "https://"$(kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/if/flow/initial-setup/
# after you finished the initial set up process, it's safe to open public access to authelia
kl apply -k ./auth/authelia/httproute-public/
kl -n authelia get httproute

# print default user login
echo "authelia-admin@authelia.$(kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}")"

# authelia has single issuer URL for all projects/apps
# print issuer URL
echo https://$(kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
# print discovery URL
echo https://$(kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration
curl https://$(kl -n authelia get httproute authelia-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration | jq

```

Don't forget to enable `Projects -> your_project -> your_application -> Grant Types -> Refresh Token`.

# Cleanup

```bash
kl -n authelia delete job init
kl -n authelia delete job setup
kl delete -k ./auth/authelia/
kl delete -k ./auth/authelia/postgres-cnpg/
kl delete ns authelia
```
