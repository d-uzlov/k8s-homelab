
# postgres cluster for lldap

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../auth/lldap/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./auth/lldap/postgres-cnpg/backups/env/

cluster_name=
namespace=auth-lldap
user_name=${cluster_name}.$namespace.$(openssl rand -hex 3)

 cat << EOF > ./auth/lldap/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./auth/lldap/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./auth/lldap/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./auth/lldap/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-lldap-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./auth/lldap/postgres-cnpg/backups/

kl -n auth-lldap get objectstore
kl -n auth-lldap describe objectstore s3-lldap-backup

```

# deploy postgres

```bash

mkdir -p ./auth/lldap/postgres-cnpg/env/

cp ./auth/lldap/postgres-cnpg/pg-lldap.template.yaml ./auth/lldap/postgres-cnpg/env/pg-lldap.yaml

# manually edit ./auth/lldap/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./auth/lldap/postgres-cnpg/env/pg-lldap.yaml

kl -n auth-lldap get cluster
kl -n auth-lldap describe cluster pg-lldap
kl -n auth-lldap get pvc
kl -n auth-lldap get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-lldap get svc
kl -n auth-lldap get secrets
kl cnpg -n auth-lldap status pg-lldap

# show access credentials
kl -n auth-lldap get secret pg-lldap-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'
kl -n auth-lldap get secret pg-lldap-superuser -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./auth/lldap/postgres-cnpg/backups/scheduled-backup.template.yaml ./auth/lldap/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./auth/lldap/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n auth-lldap get scheduledbackup
kl -n auth-lldap get backup

# change primary instance
kl cnpg -n auth-lldap promote pg-lldap pg-lldap-1
kl cnpg -n auth-lldap promote pg-lldap pg-lldap-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./auth/lldap/postgres-cnpg/env/pg-lldap.yaml
# k8s backup objects will be deleted, but underlying data in s3 will remain
kl -n auth-lldap delete scheduledbackup pg-lldap-daily

kl -n auth-lldap get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-lldap get pvc

(. ./auth/lldap/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./auth/lldap/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
