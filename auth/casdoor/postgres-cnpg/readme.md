
# postgres cluster for casdoor

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../auth/casdoor/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./auth/casdoor/postgres-cnpg/backups/env/

cluster_name=
namespace=casdoor
user_name=${cluster_name}.$namespace.$(openssl rand -hex 10)

 cat << EOF > ./auth/casdoor/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./auth/casdoor/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./auth/casdoor/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./auth/casdoor/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-casdoor-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./auth/casdoor/postgres-cnpg/backups/

kl -n casdoor get objectstore
kl -n casdoor describe objectstore s3-casdoor-backup

```

# deploy postgres

```bash

mkdir -p ./auth/casdoor/postgres-cnpg/env/

cp ./auth/casdoor/postgres-cnpg/pg-casdoor.template.yaml ./auth/casdoor/postgres-cnpg/env/pg-casdoor.yaml

# manually edit ./auth/casdoor/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./auth/casdoor/postgres-cnpg/env/pg-casdoor.yaml

kl -n casdoor get cluster
kl -n casdoor describe cluster pg-casdoor
kl -n casdoor get pvc
kl -n casdoor get pods -o wide -L role -L cnpg.io/jobRole
kl -n casdoor get svc
kl -n casdoor get secrets
kl cnpg -n casdoor status pg-casdoor

# show access credentials
kl -n casdoor get secret pg-casdoor-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./auth/casdoor/postgres-cnpg/backups/scheduled-backup.template.yaml ./auth/casdoor/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./auth/casdoor/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n casdoor get scheduledbackup
kl -n casdoor get backup

# change primary instance
kl cnpg -n casdoor promote pg-casdoor pg-casdoor-1
kl cnpg -n casdoor promote pg-casdoor pg-casdoor-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./auth/casdoor/postgres-cnpg/env/pg-casdoor.yaml
kl -n casdoor delete scheduledbackup pg-casdoor-daily

kl -n casdoor get pods -o wide -L role -L cnpg.io/jobRole
kl -n casdoor get pvc

(. ./auth/casdoor/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./auth/casdoor/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
