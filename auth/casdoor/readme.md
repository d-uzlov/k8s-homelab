
# casdoor

References:
- https://github.com/casdoor/casdoor
- https://casdoor.org/docs/basic/try-with-helm

# Generate config

You only need to do this when updating the app.

```bash

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

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

Generate passwords and set up config.

```bash

kl create ns casdoor
kl label ns casdoor pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/casdoor/redis/
kl -n casdoor get pods -o wide

kl apply -k ./auth/casdoor/httproute-private/
kl -n casdoor get httproute

ingress_address=$(kl -n casdoor get httproute casdoor-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
postgres_password=$(kl -n casdoor get secret pg-casdoor-app -o json | jq -r '.data.password | @base64d')

 cat << EOF > ./auth/casdoor/env/app.conf
appname = casdoor
httpport = 8000
runmode = prod
SessionOn = true
copyrequestbody = true
driverName = postgres
dataSourceName = "user=app password=${postgres_password} host=pg-casdoor-rw port=5432 dbname=app sslmode=require"
dbName = app
redisEndpoint = redis-master:6379,db,zvVXAd3jN1rzlorPvs9q
defaultStorageProvider =
isCloudIntranet = true
authState = "casdoor"
socks5Proxy = ""
verificationCodeTimeout = 10
initScore = 0
logPostOnly = true
origin = "https://${ingress_address}"
enableGzip = true
ldapServerPort = 10389
EOF

kl apply -k ./auth/casdoor/
kl -n casdoor get pod -o wide
kl -n casdoor logs deployments/casdoor

# go to private ingress and change admin user
# default credentials (from https://casdoor.org/docs/overview#casdoor):
# user: admin
# password: 123
# generate new good password
LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32

# after you changed the admin password, it's safe to open public access to casdoor
kl apply -k ./auth/casdoor/httproute-public/
kl -n casdoor get htr

# don't forget to change the app.conf to use public address as origin

# fetch oidc info
ingress_address=$(kl -n casdoor get httproute casdoor-public -o go-template --template "{{ (index .spec.hostnames 0)}}")
curl https://${ingress_address}/.well-known/openid-configuration | jq

```

Don't forget to enable `Projects -> your_project -> your_application -> Grant Types -> Refresh Token`.

# Cleanup

```bash
kl -n casdoor delete job init
kl -n casdoor delete job setup
kl delete -k ./auth/casdoor/
kl delete ns casdoor
```
