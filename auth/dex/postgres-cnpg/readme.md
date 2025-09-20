
# postgres cluster for dex

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../auth/dex/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./auth/dex/postgres-cnpg/backups/env/

cluster_name=trixie
namespace=auth-dex
user_name=${cluster_name}.$namespace.$(openssl rand -hex 3)

 cat << EOF > ./auth/dex/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./auth/dex/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./auth/dex/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./auth/dex/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-dex-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./auth/dex/postgres-cnpg/backups/

kl -n auth-dex get objectstore
kl -n auth-dex describe objectstore s3-dex-backup

```

# deploy postgres

```bash

mkdir -p ./auth/dex/postgres-cnpg/env/

cp ./auth/dex/postgres-cnpg/pg-dex.template.yaml ./auth/dex/postgres-cnpg/env/pg-dex.yaml

# manually edit ./auth/dex/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./auth/dex/postgres-cnpg/env/pg-dex.yaml

kl -n auth-dex get cluster
kl -n auth-dex describe cluster pg-dex
kl -n auth-dex get pvc
kl -n auth-dex get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-dex get svc
kl -n auth-dex get secrets
kl cnpg -n auth-dex status pg-dex

# show access credentials
kl -n auth-dex get secret pg-dex-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./auth/dex/postgres-cnpg/backups/scheduled-backup.template.yaml ./auth/dex/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./auth/dex/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n auth-dex get scheduledbackup
kl -n auth-dex get backup

# change primary instance
kl cnpg -n auth-dex promote pg-dex pg-dex-1
kl cnpg -n auth-dex promote pg-dex pg-dex-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./auth/dex/postgres-cnpg/env/pg-dex.yaml
kl -n auth-dex delete scheduledbackup pg-dex-daily

kl -n auth-dex get pods -o wide -L role -L cnpg.io/jobRole
kl -n auth-dex get pvc

(. ./auth/dex/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./auth/dex/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
