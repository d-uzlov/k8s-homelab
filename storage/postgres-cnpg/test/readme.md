
# test CNPG

References:
- https://cloudnative-pg.io/documentation/1.25/samples/
- https://blog.jirapongpansak.com/say-goodbye-to-data-loss-cnpgs-backup-and-restore-will-change-your-life-04bcab281214

This deployment sets up backups to S3 storage.
If you don't have S3, you will need to disable S3 backup configuration
and remove scheduled backup to S3.

```bash

mkdir -p ./storage/postgres-cnpg/test/env/

cp ./storage/postgres-cnpg/test/postgres.template.yaml ./storage/postgres-cnpg/test/env/pg-main.yaml

# manually edit ./storage/postgres-cnpg/test/env/pg-main.yaml
# change REPLACE_ME placeholders
# recommended size is at least 2Gi
kl get sc

kl create ns pgo-cnpg-test
kl label ns pgo-cnpg-test pod-security.kubernetes.io/enforce=baseline

kl apply -f ./storage/postgres-cnpg/test/env/pg-main.yaml

kl -n pgo-cnpg-test get cluster
kl -n pgo-cnpg-test describe cluster pg-main
kl -n pgo-cnpg-test get pvc
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl -n pgo-cnpg-test get svc
kl -n pgo-cnpg-test get secrets
kl cnpg -n pgo-cnpg-test status pg-main

kl -n pgo-cnpg logs deployments/cnpg manager --tail 20 --follow > ./cnpg.log

# change primary instance
kl cnpg -n pgo-cnpg-test promote pg-main pg-main-1
kl cnpg -n pgo-cnpg-test promote pg-main pg-main-2

```

# accessing postgres

```bash

# show connection secret contents
kl -n pgo-cnpg-test get secret pg-main-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# list users
kl -n pgo-cnpg-test exec pods/pg-main-1 -- psql template1 --command '\du'
# list databases
kl -n pgo-cnpg-test exec pods/pg-main-1 -- psql --list

# "cnpg psql" can automatically finds the master instance
kl cnpg -n pgo-cnpg-test psql pg-main -- --command '\du'
kl cnpg -n pgo-cnpg-test psql pg-main -- --list
# list all existing tables
kl cnpg -n pgo-cnpg-test psql pg-main -- -c '\dt *.*'
# run interactive psql
kl cnpg -n pgo-cnpg-test psql pg-main

# create pod with pgadmin management console
kl cnpg -n pgo-cnpg-test pgadmin4 --mode desktop pg-main
kl -n pgo-cnpg-test get pods -o wide
kl -n pgo-cnpg-test get svc
kl -n pgo-cnpg-test port-forward svc/postgres-pgadmin4 8080:80
# delete pgadmin when you are done with it
kl cnpg -n pgo-cnpg-test pgadmin4 --dry-run pg-main | kl delete -f -

```

# backups: setup

Prerequisites:
- [minio-client](../../minio/minio-client.md)

Here we will create a new bucket for the test namespace.

In case you want to reuse an existing bucket,
or if you already ran this test previously,
note that CNPG cluster may fail to start if WAL archive folder is not empty.

```bash

# inject some data so that backup isn't empty

 kl cnpg -n pgo-cnpg-test psql pg-main -- -c "
BEGIN;
CREATE TABLE test (
  id serial primary key,
  name varchar(20) NOT NULL
);
INSERT INTO test (id, name) VALUES (1, 'qwe');
INSERT INTO test (id, name) VALUES (2, 'asd');
INSERT INTO test (id, name) VALUES (3, 'zxc');
COMMIT;
"

kl cnpg -n pgo-cnpg-test psql pg-main -- -c "SELECT * FROM test;"

mkdir -p ./storage/postgres-cnpg/test/backups/env/

cluster_name=trixie
user_name=${cluster_name}.pgo-cnpg-test.$(openssl rand -hex 10)

 cat << EOF > ./storage/postgres-cnpg/test/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./storage/postgres-cnpg/test/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  mc admin policy create ${minio_alias} $policy_name /dev/stdin << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${bucket_name}/*",
        "arn:aws:s3:::${bucket_name}"
      ]
    }
  ]
}
EOF
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./storage/postgres-cnpg/test/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./storage/postgres-cnpg/test/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-postgres-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./storage/postgres-cnpg/test/backups/scheduled-backup.template.yaml ./storage/postgres-cnpg/test/backups/env/scheduled-backup.yaml

```

Additionally, you need to add plugin config
to `./storage/postgres-cnpg/test/env/pg-main.yaml`
at `.spec.plugins`:

```yaml
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: s3-postgres-backup
```

```bash

kl apply -k ./storage/postgres-cnpg/test/backups/

kl -n pgo-cnpg-test get objectstore
kl -n pgo-cnpg-test describe objectstore s3-postgres-backup

# reapply the postgres Cluster manifest
kl apply -f ./storage/postgres-cnpg/test/env/pg-main.yaml

kl cnpg -n pgo-cnpg-test status pg-main
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole

# check logs in case something went wrong
kl -n pgo-cnpg logs deployments/cnpg manager --tail 10
kl -n pgo-cnpg logs deployments/barman-cloud --tail 10

kl -n pgo-cnpg-test get scheduledbackup
kl -n pgo-cnpg-test describe scheduledbackup postgres-daily

kl -n pgo-cnpg-test get backup

```

# test backups

```bash

# trigger a backup
kl cnpg backup -n pgo-cnpg-test pg-main --backup-name pg-main-by-cnpg --method plugin --plugin-name barman-cloud.cloudnative-pg.io
kl -n pgo-cnpg-test get backup
kl -n pgo-cnpg-test describe backup pg-main-by-cnpg
kl -n pgo-cnpg-test delete backup pg-main-by-cnpg

# alternative way to create backups

 kl -n pgo-cnpg-test apply -f - << EOF
---
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: pg-main-by-manifest
spec:
  cluster:
    name: pg-main
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
EOF

kl -n pgo-cnpg-test get backup
kl -n pgo-cnpg-test describe backup pg-main-by-manifest
kl -n pgo-cnpg-test delete backup pg-main-by-manifest

# check bucket content after backups are created
(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

# we set 'retentionPolicy: 7d' above, and we should have daily backups
# so 10 days of retention in the s3 storage should be enough
(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc ilm rule add ${minio_alias}/$bucket_name/pg-backup --expire-days "10")
(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc ilm rule ls ${minio_alias}/$bucket_name)

```

Backup files are NOT deleted when you delete k8s resources.
This is why we configure expiration in minio.

# restore from backup

References:
- https://cloudnative-pg.io/documentation/1.27/recovery/

```bash

cp ./storage/postgres-cnpg/test/env/pg-main.yaml ./storage/postgres-cnpg/test/env/pg-restored.yaml
sed -i 's/name: pg-main/name: pg-restored/' ./storage/postgres-cnpg/test/env/pg-restored.yaml

# to restore from a backup,
# you need to change .spec.bootstrap and configure .spec.externalClusters

 cat << EOF >> ./storage/postgres-cnpg/test/env/pg-restored.yaml
  bootstrap:
    recovery:
      source: main
      # recoveryTarget:
      #   # Time base target for the recovery
      #   targetTime: "2023-08-11 11:14:21.00000+02"
  externalClusters:
  - name: main
    plugin:
      name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: s3-postgres-backup
        serverName: pg-main
EOF

# in case you already deployed test previously, delete old backup files
(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc rm --recursive --force ${minio_alias}/$bucket_name/pg-backup/pg-restored)

kl apply -f ./storage/postgres-cnpg/test/env/pg-restored.yaml
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl cnpg -n pgo-cnpg-test status restored
kl -n pgo-cnpg-test get cluster

# compare contents in main and restored clusters
kl cnpg -n pgo-cnpg-test psql pg-main -- -c "SELECT * FROM test;"
kl cnpg -n pgo-cnpg-test psql pg-restored -- -c "SELECT * FROM test;"

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./storage/postgres-cnpg/test/env/pg-restored.yaml
kl delete -f ./storage/postgres-cnpg/test/env/pg-main.yaml

kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl -n pgo-cnpg-test get pvc

kl delete ns pgo-cnpg-test

(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./storage/postgres-cnpg/test/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
