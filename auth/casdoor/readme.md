
# casdoor

References:
- https://github.com/casdoor/casdoor
- https://casdoor.org/docs/basic/try-with-helm

# config

```bash

mkdir -p ./auth/casdoor/dragonfly/env/

 cat << EOF > ./auth/casdoor/dragonfly/env/password.env
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

kl get sc
storage_class=tulip-nvmeof
sed "s/storageClassName: REPLACE_ME/storageClassName: $storage_class/" ./auth/casdoor/dragonfly/dragonfly-casdoor.template.yaml > ./auth/casdoor/dragonfly/env/dragonfly-casdoor.yaml

mkdir -p ./auth/casdoor/env/

# edit config manually (add passwords and address)

 cat << EOF > ./auth/casdoor/env/app.conf
appname = casdoor
httpport = 8000
runmode = prod
SessionOn = true
copyrequestbody = true
driverName = postgres
dataSourceName = "user=app password=${postgres_password} host=pg-casdoor-rw port=5432 dbname=app sslmode=require"
dbName = app
redisEndpoint = df-casdoor:6379,db,${redis_password}
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

```

# deploy

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

```bash

kl create ns casdoor
kl label ns casdoor pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/casdoor/dragonfly/
kl -n casdoor get dragonfly
kl -n casdoor get pod -o wide -L role
kl -n casdoor get pvc
kl -n casdoor get svc

kl apply -k ./auth/casdoor/httproute-private/
kl -n casdoor get httproute

ingress_address=$(kl -n casdoor get httproute casdoor-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
postgres_password=$(kl -n casdoor get secret pg-casdoor-app -o json | jq -r '.data.password | @base64d')

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

# Cleanup

```bash
kl delete -k ./auth/casdoor/
kl delete -k ./auth/casdoor/dragonfly/
kl delete ns casdoor
```
