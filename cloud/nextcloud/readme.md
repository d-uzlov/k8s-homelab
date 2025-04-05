
# Nextcloud

References:
- https://github.com/nextcloud/docker
- https://hub.docker.com/_/nextcloud/
- https://github.com/aptible/supercronic
- https://hub.docker.com/_/nginx
- https://chrismoore.ca/2018/10/finding-the-correct-pm-max-children-settings-for-php-fpm/

# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Storage setup

Set storage classes for different data types:

```bash

mkdir -p ./cloud/nextcloud/pvc/env/
 cat << EOF > ./cloud/nextcloud/pvc/env/pvc.env
# userdata uses ReadWriteMany type volumes
userdata=fast
userdata_size=1Ti

# config uses ReadWriteMany type volumes
config=fast
config_size=1Gi
EOF

# mkdir -p ./cloud/nextcloud/postgres/env/
#  cat << EOF > ./cloud/nextcloud/postgres/env/postgres-patch.yaml
# ---
# apiVersion: acid.zalan.do/v1
# kind: postgresql
# metadata:
#   name: postgres
# spec:
#   volume:
#     # 1Gi for WAL (default size)
#     # 1Gi for database itself (seems to be fine for small instance)
#     size: 2Gi
#     storageClass: $storageClass
# EOF

# ======== Postgres setup ========

mkdir -p ./cloud/nextcloud/postgres-cnpg/env/

storage_class=
storage_size=1Gi
s3_server_address=http://nas.example.com:9000/
# make sure that bucket path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
s3_bucket_path=s3://postgres-test/subfolder/

 cat << EOF > ./cloud/nextcloud/postgres-cnpg/env/backup-s3-credentials.env
key=dmzER5pleUdusVaG9n8d
secret=zD07Jfk483DAJU8soRLZ4x9xdbtsU1QPcnU2eCp7
EOF

 cat << EOF > ./cloud/nextcloud/postgres-cnpg/env/patch.env
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

```

# Config setup

Generate passwords and set up config.

```bash

mkdir -p ./cloud/nextcloud/main-app/env/

 cat << EOF > ./cloud/nextcloud/main-app/env/passwords.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
admin_name=admin
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

 cat << EOF > ./cloud/nextcloud/main-app/env/nextcloud.env
# k8s pod CIDR
trusted_proxies=10.201.0.0/16
EOF

```

# Deploy

```bash

kl create ns nextcloud
kl label ns nextcloud pod-security.kubernetes.io/enforce=baseline

# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/ingress-wildcard/
kl -n nextcloud get ingress

kl apply -k ./cloud/nextcloud/httproute-private/
kl apply -k ./cloud/nextcloud/httproute-public/
kl -n nextcloud get httproute

# tell nextcloud to allow connections via ingress domain address
nextcloud_public_domain=$(kl -n nextcloud get ingress nextcloud -o go-template --template "{{ (index .spec.rules 0).host}}")
kl -n nextcloud create configmap public-domain --from-literal public_domain="*$nextcloud_public_domain*" -o yaml --dry-run=client | kl apply -f -

kl apply -k ./cloud/nextcloud/postgres-cnpg/

kl -n nextcloud get cluster
kl -n nextcloud describe cluster nextcloud-cnpg
kl -n nextcloud get pvc
kl -n nextcloud get pods -o wide -L role -L cnpg.io/jobRole
kl -n nextcloud get svc
kl -n nextcloud get secrets
kl cnpg -n nextcloud status nextcloud-cnpg

kl cnpg -n nextcloud psql nextcloud-cnpg app < ./cloud/nextcloud/postgres-dump.sql

# show connection secret contents
kl -n nextcloud get secret nextcloud-cnpg-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

kl apply -k ./cloud/nextcloud/pvc/
kl -n nextcloud get pvc

kl apply -k ./cloud/nextcloud/main-app/
kl -n nextcloud get pod -o wide

```

TODO support dynamic postgres password update without manual config edits.

# Uninstall

```bash
kl delete -k ./cloud/nextcloud/notifications/
kl delete -k ./cloud/nextcloud/main-app/
kl delete -k ./cloud/nextcloud/pvc/
kl delete -k ./cloud/nextcloud/postgres-cnpg/
kl delete ns nextcloud
```

# Apps

TODO

Potentially interesting apps:
- Archive manager
- Contacts
- Draw.io
- Extract
- Full text search (requires external setup)
- Notes
- Recognize

Investigate `allow_local_remote_servers` option.
