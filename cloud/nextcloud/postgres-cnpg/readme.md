
# postgres cluster for nextcloud

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../cloud/nextcloud/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./cloud/nextcloud/postgres-cnpg/backups/env/

cluster_name=
namespace=nextcloud
user_name=${cluster_name}.$namespace.$(openssl rand -hex 10)

 cat << EOF > ./cloud/nextcloud/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./cloud/nextcloud/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./cloud/nextcloud/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./cloud/nextcloud/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-nextcloud-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./cloud/nextcloud/postgres-cnpg/backups/

kl -n nextcloud get objectstore
kl -n nextcloud describe objectstore s3-postgres-backup

```

# deploy postgres

```bash

mkdir -p ./cloud/nextcloud/postgres-cnpg/env/

cp ./cloud/nextcloud/postgres-cnpg/pg-nextcloud.template.yaml ./cloud/nextcloud/postgres-cnpg/env/pg-nextcloud.yaml

# manually edit ./cloud/nextcloud/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./cloud/nextcloud/postgres-cnpg/env/pg-nextcloud.yaml

kl -n nextcloud get cluster
kl -n nextcloud describe cluster pg-nextcloud
kl -n nextcloud get pvc
kl -n nextcloud get pods -o wide -L role -L cnpg.io/jobRole
kl -n nextcloud get svc
kl -n nextcloud get secrets
kl cnpg -n nextcloud status pg-nextcloud

# show access credentials
kl -n nextcloud get secret pg-nextcloud-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./cloud/nextcloud/postgres-cnpg/backups/scheduled-backup.template.yaml ./cloud/nextcloud/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./cloud/nextcloud/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n nextcloud get scheduledbackup
kl -n nextcloud get backup

# change primary instance
kl cnpg -n nextcloud promote pg-nextcloud pg-nextcloud-1
kl cnpg -n nextcloud promote pg-nextcloud pg-nextcloud-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./cloud/nextcloud/postgres-cnpg/env/pg-nextcloud.yaml
kl -n nextcloud delete scheduledbackup pg-nextcloud-daily

kl -n nextcloud get pods -o wide -L role -L cnpg.io/jobRole
kl -n nextcloud get pvc

(. ./cloud/nextcloud/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./cloud/nextcloud/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
