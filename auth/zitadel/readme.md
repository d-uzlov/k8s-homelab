
# Authentik

Authentik is an identity provider.
It can be used to do unified auth across many applications.
It can also be used as a proxy, adding auth to simple applications that don't have it on its own.

References:
- https://goauthentik.io/#comparison
- https://xpufx.com/posts/protecting-your-first-app-with-authentik/
- https://medium.com/@wessel__/istio-with-authentik-securing-your-cluster-and-providing-authentication-and-authorization-b5e48b331920

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

# consult your email provider for info how to connect to smtp
# if you don't want to use it, leave everything empty
# for example:
# - yandex: https://yandex.ru/support/yandex-360/customers/mail/ru/mail-clients/others.html#smtpsetting
# - google: https://support.google.com/a/answer/176600?hl=en
#  cat << EOF > ./auth/authentik/env/authentik-smtp.env
# auth_smtp_host=AUTOREPLACE_SMTP_HOST
# auth_smtp_port=AUTOREPLACE_SMTP_PORT
# auth_smtp_username=AUTOREPLACE_SMTP_USERNAME
# auth_smtp_password=AUTOREPLACE_SMTP_PASSWORD
# auth_smtp_use_tls=false
# auth_smtp_use_ssl=true
# # example: "Authentik <user@example.com>"
# auth_smtp_from="AUTOREPLACE_SMTP_FROM"
# EOF

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

# Additional configuration

- [General tips](./tips.md)
- [Auth proxy for applications that don't support auth natively](./proxy.md)
- [Customize auth options and appearance](./flow-configuration.md)
