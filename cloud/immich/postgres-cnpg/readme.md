
# postgres cluster for immich

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../cloud/immich/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./cloud/immich/postgres-cnpg/backups/env/

cluster_name=trixie
namespace=immich
user_name=${cluster_name}.$namespace.$(openssl rand -hex 3)

 cat << EOF > ./cloud/immich/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./cloud/immich/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./cloud/immich/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./cloud/immich/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-immich-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./cloud/immich/postgres-cnpg/backups/

kl -n immich get objectstore
kl -n immich describe objectstore s3-immich-backup

```

# deploy postgres

```bash

mkdir -p ./cloud/immich/postgres-cnpg/env/

cp ./cloud/immich/postgres-cnpg/pg-immich.template.yaml ./cloud/immich/postgres-cnpg/env/pg-immich.yaml

# manually edit ./cloud/immich/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
# when migrating from external database see "migrating from external database" section below
kl get sc

kl apply -f ./cloud/immich/postgres-cnpg/env/pg-immich.yaml

kl -n immich get cluster
kl -n immich describe cluster pg-immich
kl -n immich get pvc
kl -n immich get pods -o wide -L role -L cnpg.io/jobRole
kl -n immich get svc
kl -n immich get secrets
kl cnpg -n immich status pg-immich
kl cnpg -n immich psql pg-immich

# after postgres is ready, apply database config
kl apply -f ./cloud/immich/postgres-cnpg/database.yaml
# make sure the database config is applied successfully
kl -n immich describe database app
# kl delete -f ./cloud/immich/postgres-cnpg/database.yaml

# show access credentials
kl -n immich get secret pg-immich-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./cloud/immich/postgres-cnpg/backups/scheduled-backup.template.yaml ./cloud/immich/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./cloud/immich/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n immich get scheduledbackup
kl -n immich describe scheduledbackup
kl -n immich get backup

# change primary instance
kl cnpg -n immich promote pg-immich pg-immich-1
kl cnpg -n immich promote pg-immich pg-immich-3

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./cloud/immich/postgres-cnpg/env/pg-immich.yaml
kl -n immich delete scheduledbackup pg-immich-daily

kl -n immich get pods -o wide -L role -L cnpg.io/jobRole
kl -n immich get pvc

(. ./cloud/immich/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)
(. ./cloud/immich/postgres-cnpg/backups/env/s3-info.env; mc ls ${minio_alias}/$bucket_name/pg-backup/pg-immich/wals/)
(. ./cloud/immich/postgres-cnpg/backups/env/s3-info.env; mc du --depth 2 ${minio_alias}/$bucket_name/pg-backup/pg-immich/wals/)
(. ./cloud/immich/postgres-cnpg/backups/env/s3-info.env; mc du --depth 2 ${minio_alias}/$bucket_name/pg-backup/pg-immich/base/)

 (
  # warning, this will irreversibly remove all backups
  . ./cloud/immich/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```

# migrating from external database

Add this to your cluster definition:

```yaml
  bootstrap:
    initdb:
      import:
        type: microservice
        databases:
        - immich
        source:
          externalCluster: immich-standalone-db
  externalClusters:
  - name: immich-standalone-db
    connectionParameters:
      host: immich-postgresql.immich.svc.cluster.local
      user: immich
      dbname: immich
    password:
      name: postgres-password-99c5dg4tk8
      key: password
```

Don't forget to substitute `externalClusters.0.password` with your password secret info.

Before deploying CNPG postgres manually delete vecto.rs extension in the old deployment:
`drop extension vectors;`.

When doing migration, disable Immich first, then completely set up database, then re-enable Immich.

References:
- https://github.com/immich-app/immich-charts/issues/149
- https://github.com/camrossi/home-cluster/blob/main/apps/immich/DB_Migration.md
- https://cloudnative-pg.io/documentation/1.27/database_import/
