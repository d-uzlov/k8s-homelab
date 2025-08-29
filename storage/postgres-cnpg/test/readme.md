
# test CNPG

References:
- https://cloudnative-pg.io/documentation/1.25/samples/
- https://blog.jirapongpansak.com/say-goodbye-to-data-loss-cnpgs-backup-and-restore-will-change-your-life-04bcab281214

This deployment sets up backups to S3 storage.
If you don't have S3, you will need to disable S3 backup configuration
and remove scheduled backup to S3.

```bash

mkdir -p ./storage/postgres-cnpg/test/env/

cp ./storage/postgres-cnpg/test/postgres.template.yaml ./storage/postgres-cnpg/test/env/postgres.yaml

# manually edit ./storage/postgres-cnpg/test/env/postgres.yaml
# change REPLACE_ME placeholders
# recommended size is at least 2Gi
kl get sc

kl create ns pgo-cnpg-test
kl label ns pgo-cnpg-test pod-security.kubernetes.io/enforce=baseline

kl apply -f ./storage/postgres-cnpg/test/env/postgres.yaml

kl -n pgo-cnpg-test get cluster
kl -n pgo-cnpg-test describe cluster postgres
kl -n pgo-cnpg-test get pvc
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl -n pgo-cnpg-test get svc
kl -n pgo-cnpg-test get secrets
kl cnpg -n pgo-cnpg-test status postgres

kl -n pgo-cnpg logs deployments/cnpg manager --tail 20 --follow > ./cnpg.log

# change primary instance
kl cnpg -n pgo-cnpg-test promote postgres postgres-1
kl cnpg -n pgo-cnpg-test promote postgres postgres-2

# warning: PVCs will be deleted automatically
kl delete -f ./storage/postgres-cnpg/test/env/postgres.yaml
kl delete ns pgo-cnpg-test

```

# accessing postgres

```bash

# show connection secret contents
kl -n pgo-cnpg-test get secret postgres-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# list users
kl -n pgo-cnpg-test exec pods/postgres-1 -- psql template1 --command '\du'
# list databases
kl -n pgo-cnpg-test exec pods/postgres-1 -- psql --list

# "cnpg psql" can automatically finds the master instance
kl cnpg -n pgo-cnpg-test psql postgres -- --command '\du'
kl cnpg -n pgo-cnpg-test psql postgres -- --list
# list all existing tables
kl cnpg -n pgo-cnpg-test psql postgres -- -c '\dt *.*'
# run interactive psql
kl cnpg -n pgo-cnpg-test psql postgres

# create pod with pgadmin management console
kl cnpg -n pgo-cnpg-test pgadmin4 --mode desktop postgres
kl -n pgo-cnpg-test get pods -o wide
kl -n pgo-cnpg-test get svc
kl -n pgo-cnpg-test port-forward svc/postgres-pgadmin4 8080:80
# delete pgadmin when you are done with it
kl cnpg -n pgo-cnpg-test pgadmin4 --dry-run postgres | kl delete -f -

```

# backups: setup

Prerequisites:
- [minio-client](../../minio/minio-client.md)

```bash

mkdir -p ./storage/postgres-cnpg/test/backups/env/

cluster_name=trixie
user_name="${cluster_name}.pgo-cnpg-test.$(openssl rand -hex 10)"
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name

 cat << EOF > ./storage/postgres-cnpg/test/backups/env/s3-info.env
user_name=$user_name
user_secret=$user_secret
bucket_name=$bucket_name
policy_name=$policy_name
EOF

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

s3_server_address=http://nas.example.com:9000/

 cat << EOF > ./storage/postgres-cnpg/test/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-postgres-backup
spec:
  configuration:
    endpointURL: $s3_server_address
    destinationPath: s3://$bucket_name/pg-backup/
EOF

# make sure that bucket path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
# s3_bucket_path=

kl apply -k ./storage/postgres-cnpg/test/backups/
kl -n pgo-cnpg-test get objectstore
kl -n pgo-cnpg-test describe objectstore s3-postgres-backup

cat << EOF
EOF

```

Additionally, you need to add plugin config
to `./storage/postgres-cnpg/test/env/postgres.yaml`
at `.spec.plugins`:

```yaml
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: s3-postgres-backup
```

Don't forget to reapply the manifest:

```bash
kl apply -f ./storage/postgres-cnpg/test/env/postgres.yaml
kl cnpg -n pgo-cnpg-test status postgres
# check logs in case something went wrong
kl -n pgo-cnpg logs deployments/cnpg manager --tail 10
kl -n pgo-cnpg logs deployments/barman-cloud --tail 10
```

# backups: create

```bash

# trigger a backup
kl cnpg backup -n pgo-cnpg-test postgres --backup-name backup-by-cnpg --method plugin --plugin-name barman-cloud.cloudnative-pg.io
kl -n pgo-cnpg-test get backup
kl -n pgo-cnpg-test describe backup backup-by-cnpg
kl -n pgo-cnpg-test delete backup backup-by-cnpg

# alternative way to create backups

 kl -n pgo-cnpg-test apply -f - << EOF
---
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: backup-by-manifest
spec:
  cluster:
    name: postgres
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
EOF
kl -n pgo-cnpg-test get backup
kl -n pgo-cnpg-test describe backup backup-by-manifest
kl -n pgo-cnpg-test delete backup backup-by-manifest

# check bucket content after backups are created
(. ./storage/postgres-cnpg/test/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

# check automatic backups
kl -n pgo-cnpg-test get scheduledbackup
kl -n pgo-cnpg-test describe scheduledbackup

```

Backup files are NOT deleted when you delete the namespace.

# restore from backup

```bash

cp ./storage/postgres-cnpg/test/env/postgres.yaml ./storage/postgres-cnpg/test/env/postgres-restored.yaml
sed -i 's/name: postgres/name: restored/' ./storage/postgres-cnpg/test/env/postgres-restored.yaml

 cat << EOF >> ./storage/postgres-cnpg/test/env/postgres-restored.yaml
  externalClusters:
  - name: source
    plugin:
      name: barman-cloud.cloudnative-pg.io
      parameters:
        barmanObjectName: s3-postgres-backup
        serverName: postgres
EOF

kl apply -f ./storage/postgres-cnpg/test/env/postgres-restored.yaml
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl cnpg -n pgo-cnpg-test status restored
kl -n pgo-cnpg-test get cluster

```
