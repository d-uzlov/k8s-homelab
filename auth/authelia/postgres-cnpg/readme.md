
# postgres cluster for authelia

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../auth/authelia/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./auth/authelia/postgres-cnpg/backups/env/

cluster_name=trixie
namespace=auth-authelia
user_name=${cluster_name}.$namespace.$(openssl rand -hex 3)

 cat << EOF > ./auth/authelia/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./auth/authelia/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./auth/authelia/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./auth/authelia/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-authelia-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./auth/authelia/postgres-cnpg/backups/

kl -n auth-authelia get objectstore
kl -n auth-authelia describe objectstore s3-authelia-backup

```

# deploy postgres

```bash

mkdir -p ./auth/authelia/postgres-cnpg/env/

cp ./auth/authelia/postgres-cnpg/pg-authelia.template.yaml ./auth/authelia/postgres-cnpg/env/pg-authelia.yaml

# manually edit ./auth/authelia/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./auth/authelia/postgres-cnpg/env/pg-authelia.yaml

kl -n auth-authelia get cluster
kl -n auth-authelia describe cluster pg-authelia
kl -n auth-authelia get pvc
kl -n auth-authelia get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-authelia get svc
kl -n auth-authelia get secrets
kl cnpg -n auth-authelia status pg-authelia

# show access credentials
kl -n auth-authelia get secret pg-authelia-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'
kl -n auth-authelia get secret pg-authelia-superuser -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./auth/authelia/postgres-cnpg/backups/scheduled-backup.template.yaml ./auth/authelia/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./auth/authelia/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n auth-authelia get scheduledbackup
kl -n auth-authelia get backup

# change primary instance
kl cnpg -n auth-authelia promote pg-authelia pg-authelia-1
kl cnpg -n auth-authelia promote pg-authelia pg-authelia-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./auth/authelia/postgres-cnpg/env/pg-authelia.yaml
# k8s backup objects will be deleted, but underlying data in s3 will remain
kl -n auth-authelia delete scheduledbackup pg-authelia-daily

kl -n auth-authelia get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-authelia get pvc

(. ./auth/authelia/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./auth/authelia/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
