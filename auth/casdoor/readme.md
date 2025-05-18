
# casdoor

References:
- https://casdoor.org/docs/basic/try-with-helm

# Generate config

You only need to do this when updating the app.

```bash
# https://hub.docker.com/r/casbin/casdoor-helm-charts/tags
helm show values oci://registry-1.docker.io/casbin/casdoor-helm-charts --version v1.910.0 > ./auth/casdoor/default-values.yaml

helm template \
  casdoor \
  oci://registry-1.docker.io/casbin/casdoor-helm-charts \
  --version v1.910.0 \
  --namespace casdoor \
  --values ./auth/casdoor/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/casdoor/casdoor.gen.yaml

# https://hub.docker.com/r/bitnamicharts/redis/tags
helm show values oci://registry-1.docker.io/bitnamicharts/redis --version 20.6.2 > ./auth/casdoor/redis/default-values.yaml

helm template \
  redis \
  oci://registry-1.docker.io/bitnamicharts/redis \
  --version 20.6.2 \
  --namespace casdoor \
  --values ./auth/casdoor/redis/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e 's/redis-data/data/' \
  > ./auth/casdoor/redis/redis.gen.yaml

```

# Deploy

Generate passwords and set up config.

```bash

# ======== Postgres setup ========

mkdir -p ./auth/casdoor/postgres-cnpg/env/

storage_class=
storage_size=1Gi
s3_server_address=http://nas.example.com:9000/
# make sure that bucket path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
s3_bucket_path=s3://postgres-test/subfolder/

 cat << EOF > ./auth/casdoor/postgres-cnpg/env/backup-s3-credentials.env
key=dmzER5pleUdusVaG9n8d
secret=zD07Jfk483DAJU8soRLZ4x9xdbtsU1QPcnU2eCp7
EOF

 cat << EOF > ./auth/casdoor/postgres-cnpg/env/patch.env
---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres
spec:
  instances: 2
  storage:
    size: $storage_size
    storageClass: $storage_class
  backup:
    barmanObjectStore:
      endpointURL: $s3_server_address
      destinationPath: $s3_bucket_path
EOF

mkdir -p ./auth/casdoor/config/env/
 cat << EOF > ./auth/casdoor/config/env/master_key.env
master_key=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

```

```bash

kl create ns casdoor
kl label ns casdoor pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/casdoor/postgres-cnpg/

kl -n casdoor get cluster
kl -n casdoor describe cluster cnpg
kl -n casdoor get pvc
kl -n casdoor get pods -o wide -L role -L cnpg.io/jobRole
kl -n casdoor get svc
kl -n casdoor get secrets
kl cnpg -n casdoor status cnpg

kl apply -k ./auth/casdoor/redis/
kl -n casdoor get pods -o wide

# show postgres connection secret contents
kl -n casdoor get secret cnpg-app -o json | jq -r '.data | to_entries | map(.value |= @base64d) | from_entries'

kl apply -k ./auth/casdoor/httproute-private/
kl -n casdoor get httproute

public_address=https://$(kl -n casdoor get httproute casdoor-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
cat << EOF > ./auth/casdoor/env/app.conf
appname = casdoor
httpport = 8000
runmode = prod
SessionOn = true
copyrequestbody = true
driverName = postgres
dataSourceName = "user=app password=lBZ4801gWRLlllJpi4cdQV4ebEuqUGDWA1rzoDA17kIYOYFgihZLLAjuYCxw2aas host=cnpg-rw port=5432 dbname=app sslmode=require"
dbName = app
redisEndpoint = redis-master:6379,db,zvVXAd3jN1rzlorPvs9q
defaultStorageProvider =
isCloudIntranet = true
authState = "casdoor"
socks5Proxy = ""
verificationCodeTimeout = 10
initScore = 0
logPostOnly = true
origin = "$public_address"
enableGzip = true
ldapServerPort = 10389
EOF

kl apply -k ./auth/casdoor/
kl -n casdoor get pod -o wide
kl -n casdoor logs deployments/casdoor

# default credentials:
# user: admin
# password: 123
# https://casdoor.org/docs/overview#casdoor

# after you finished the initial set up process, it's safe to open public access to casdoor
kl apply -k ./auth/casdoor/httproute-public/
kl -n casdoor get httproute

# now go to ./auth/casdoor/env/app.conf and change origin parameter

```

Don't forget to enable `Projects -> your_project -> your_application -> Grant Types -> Refresh Token`.

# Cleanup

```bash
kl -n casdoor delete job init
kl -n casdoor delete job setup
kl delete -k ./auth/casdoor/
kl delete -k ./auth/casdoor/postgres-cnpg/
kl delete ns casdoor
```
