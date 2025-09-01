
# postgres cluster for acme-dns

Requirements:
- [CNPG postgres operator](../../../storage/postgres-cnpg/readme.md)
- S3 storage. For example:
- - [minio](../../../storage/minio/readme.md)

References:
- [see cnpg test example](../../../ingress/cert-manager/acme-dns/postgres-cnpg/readme.md)

# prepare S3 (for backups)

```bash

mkdir -p ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/

cluster_name=trixie
namespace=cm-acme-dns
user_name=${cluster_name}.$namespace.$(openssl rand -hex 10)

 cat << EOF > ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/s3-info.env
user_name=$user_name
user_secret=$(openssl rand -hex 20)
bucket_name=$user_name
policy_name=$user_name
EOF

 (
  set -e
  . ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/s3-info.env;
  mc admin user add ${minio_alias} $user_name $user_secret
  mc mb ${minio_alias}/$bucket_name
  sed "s/REPLACE_ME_BUCKET_NAME/$bucket_name/" ./storage/minio/allow-bucket-access.json | mc admin policy create ${minio_alias} $policy_name /dev/stdin
  mc admin policy attach ${minio_alias} $policy_name --user $user_name
)

 (
  set -e
  . ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/s3-info.env;
  s3_server_address=$(mc alias export ${minio_alias} | jq -r .url)
  cat << EOF > ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/patch-object-store.yaml
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: s3-acme-dns-backup
spec:
  retentionPolicy: 7d
  configuration:
    endpointURL: $s3_server_address
    # note that destinationPath should NOT contain a trailing slash
    #   see here: https://github.com/cloudnative-pg/cloudnative-pg/issues/4890
    destinationPath: s3://$bucket_name/pg-backup
EOF
)

kl apply -k ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/

kl -n cm-acme-dns get objectstore
kl -n cm-acme-dns describe objectstore s3-acme-dns-backup

```

# deploy postgres

```bash

mkdir -p ./ingress/cert-manager/acme-dns/postgres-cnpg/env/

cp ./ingress/cert-manager/acme-dns/postgres-cnpg/pg-acme-dns.template.yaml ./ingress/cert-manager/acme-dns/postgres-cnpg/env/pg-acme-dns.yaml

# manually edit ./ingress/cert-manager/acme-dns/postgres-cnpg/env/pg-main.yaml
# change size and StorageClass placeholders
# recommended size is at least 2Gi
kl get sc

kl apply -f ./ingress/cert-manager/acme-dns/postgres-cnpg/env/pg-acme-dns.yaml

kl -n cm-acme-dns get cluster
kl -n cm-acme-dns describe cluster postgres
kl -n cm-acme-dns get pvc
kl -n cm-acme-dns get pods -o wide -L role -L cnpg.io/jobRole
kl -n cm-acme-dns get svc
kl -n cm-acme-dns get secrets
kl cnpg -n cm-acme-dns status postgres

# show access credentials
kl -n cm-acme-dns get secret pg-acme-dns-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

# setup backups after cluster is established
# you can adjust the schedule or suspend the backups in env/scheduled-backup.yaml
cp ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/scheduled-backup.template.yaml ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/scheduled-backup.yaml
kl apply -f ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/scheduled-backup.yaml

kl -n cm-acme-dns get scheduledbackup
kl -n cm-acme-dns get backup

# change primary instance
kl cnpg -n cm-acme-dns promote postgres postgres-1
kl cnpg -n cm-acme-dns promote postgres postgres-2

```

# cleanup

```bash

# warning: PVCs will be deleted automatically
kl delete -f ./ingress/cert-manager/acme-dns/postgres-cnpg/env/pg-acme-dns.yaml
kl -n cm-acme-dns delete scheduledbackup postgres-daily

kl -n cm-acme-dns get pods -o wide -L role -L cnpg.io/jobRole
kl -n cm-acme-dns get pvc

(. ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/s3-info.env; mc tree ${minio_alias}/$bucket_name/pg-backup)

 (
  # warning, this will irreversibly remove all backups
  . ./ingress/cert-manager/acme-dns/postgres-cnpg/backups/env/s3-info.env;
  mc admin policy detach ${minio_alias} $policy_name --user $user_name
  mc admin policy rm ${minio_alias} $policy_name
  mc admin user rm ${minio_alias} $user_name
  mc rb ${minio_alias}/$bucket_name --force
)

```
