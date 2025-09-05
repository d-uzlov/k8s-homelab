
# postgres cluster for zitadel

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../auth/zitadel/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./auth/zitadel/postgres-cnpg/backups/env/

cluster_name=trixie
namespace=zitadel
user_name=${cluster_name}.$namespace.$(openssl rand -hex 3)

 cat << EOF > ./auth/zitadel/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./auth/zitadel/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./auth/zitadel/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./auth/zitadel/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-zitadel-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./auth/zitadel/postgres-cnpg/backups/

kl -n zitadel get objectstore
kl -n zitadel describe objectstore s3-zitadel-backup

```

# deploy postgres

```bash

mkdir -p ./auth/zitadel/postgres-cnpg/env/

cp ./auth/zitadel/postgres-cnpg/pg-zitadel.template.yaml ./auth/zitadel/postgres-cnpg/env/pg-zitadel.yaml

# manually edit ./auth/zitadel/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./auth/zitadel/postgres-cnpg/env/pg-zitadel.yaml

kl -n zitadel get cluster
kl -n zitadel describe cluster pg-zitadel
kl -n zitadel get pvc
kl -n zitadel get pods -o wide -L role -L cnpg.io/jobRole
kl -n zitadel get svc
kl -n zitadel get secrets
kl cnpg -n zitadel status pg-zitadel

# show access credentials
kl -n zitadel get secret pg-zitadel-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'
kl -n zitadel get secret pg-zitadel-superuser -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./auth/zitadel/postgres-cnpg/backups/scheduled-backup.template.yaml ./auth/zitadel/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./auth/zitadel/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n zitadel get scheduledbackup
kl -n zitadel get backup

# change primary instance
kl cnpg -n zitadel promote pg-zitadel pg-zitadel-1
kl cnpg -n zitadel promote pg-zitadel pg-zitadel-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./auth/zitadel/postgres-cnpg/env/pg-zitadel.yaml
kl -n zitadel delete scheduledbackup pg-zitadel-daily

kl -n zitadel get pods -o wide -L role -L cnpg.io/jobRole
kl -n zitadel get pvc

(. ./auth/zitadel/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./auth/zitadel/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
