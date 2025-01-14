
# OwnCLoud Infinite Scale

References:
- https://doc.owncloud.com/ocis/next/deployment/container/orchestration/orchestration.html
- https://doc.owncloud.com/ocis/7.0/quickguide/quickguide.html
- https://github.com/owncloud/ocis-charts
- https://github.com/owncloud/ocis

Alt guide: https://helgeklein.com/blog/owncloud-infinite-scale-with-openid-connect-authentication-for-home-networks/#docker-compose-file

# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Generate config

You only need to do this when updating the app.

```bash
git clone https://github.com/owncloud/ocis-charts.git ./cloud/ocis/helm --depth 1 --branch v0.5.0
helm show values ./cloud/ocis/helm/charts/ocis > ./cloud/ocis/default-values.yaml
```

```bash
helm template \
  ocis \
  ./cloud/ocis/helm/charts/ocis \
  --namespace ocis \
  --values ./cloud/ocis/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./cloud/ocis/ocis.gen.yaml
```

# Storage setup

Set up storage for OCIS components:

```bash
mkdir -p ./cloud/ocis/pvc/env/
cat <<EOF > ./cloud/ocis/pvc/env/pvc.env
# all components use ReadWriteMany volumes
# so they can share storage if you scale them

metadata_storage_class=fast
# here are default PVC size from default helm values
idm_size=10Gi
nats_size=10Gi
search_size=10Gi
# have no idea what storagesystem is but it doesn't hold user data
storagesystem_size=5Gi
store_size=5Gi
thumbnails_size=10Gi
web_size=1Gi

user_data_storage_class=fast
storageusers_size=50Gi
EOF
```

# Local environment setup

Generate secrets and certificates:

```bash
mkdir -p ./cloud/ocis/secrets/env/
cat <<EOF > ./cloud/ocis/secrets/env/jwt-secret.env
jwt-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/machine-auth-api-key.env
machine-auth-api-key=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/storage-system.env
user-id=$(cat /proc/sys/kernel/random/uuid | tr -d '\n')
api-key=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/storage-system-jwt-secret.env
storage-system-jwt-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/transfer-secret.env
transfer-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/thumbnails-transfer-secret.env
thumbnails-transfer-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/storage-users.env
storage-uuid=$(cat /proc/sys/kernel/random/uuid | tr -d '\n')
EOF
cat <<EOF > ./cloud/ocis/secrets/env/graph.env
application-id=$(cat /proc/sys/kernel/random/uuid | tr -d '\n')
EOF
cat <<EOF > ./cloud/ocis/secrets/env/ldap-bind-secrets.env
reva-ldap-bind-password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
idp-ldap-bind-password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
graph-ldap-bind-password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF
cat <<EOF > ./cloud/ocis/secrets/env/admin-user.env
user-id=$(cat /proc/sys/kernel/random/uuid | tr -d '\n')
password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 50)
EOF

mkdir -p ./cloud/ocis/secrets/env/ldap/
openssl genrsa -out ./cloud/ocis/secrets/env/ldap/ldap-ca.key 4096
openssl req -new -x509 -days 36500 -key ./cloud/ocis/secrets/env/ldap/ldap-ca.key -out ./cloud/ocis/secrets/env/ldap/ldap-ca.crt << EOF
.
.
.
.
.
ocis-ldap-ca
.

EOF

openssl genrsa -out ./cloud/ocis/secrets/env/ldap/ldap.key 4096
openssl req -new -subj "/CN=idm" -key ./cloud/ocis/secrets/env/ldap/ldap.key -out ./cloud/ocis/secrets/env/ldap/ldap.csr
openssl x509 -req -extensions SAN \
  -extfile <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:idm")) \
  -days 36500 \
  -in ./cloud/ocis/secrets/env/ldap/ldap.csr \
  -CA ./cloud/ocis/secrets/env/ldap/ldap-ca.crt \
  -CAkey ./cloud/ocis/secrets/env/ldap/ldap-ca.key \
  -out ./cloud/ocis/secrets/env/ldap/ldap.crt \
  -CAcreateserial

mkdir -p ./cloud/ocis/secrets/env/idp/
openssl rand 32 > ./cloud/ocis/secrets/env/idp/encryption.key
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 2> /dev/null > ./cloud/ocis/secrets/env/idp/private-key.pem
```

# Deploy

```bash
kl create ns ocis
kl label ns ocis pod-security.kubernetes.io/enforce=baseline

# wildcard ingress
kl label ns --overwrite ocis copy-wild-cert=main
kl apply -k ./cloud/ocis/ingress-wildcard/
kl -n ocis get ingress

kl apply -k ./cloud/ocis/pvc/
kl -n ocis get pvc

mkdir ./cloud/ocis/env/
ocis_public_domain=$(kl -n ocis get ingress ocis -o go-template --template "{{range .spec.rules}}{{.host}}{{end}}")
cat ./cloud/ocis/ocis.gen.yaml \
  | sed -e "s/ocis.owncloud.test/$ocis_public_domain/g" \
  > ./cloud/ocis/env/ocis-mod.gen.yaml
kl apply -k ./cloud/ocis/
kl -n ocis get pod -o wide

# default user name is admin
# print admin password
echo $(kl -n ocis get secret -l ocis-secret=admin-user --template "{{range .items}}{{.data.password}}{{end}}" | base64 --decode)
```

# Cleanup

```bash
kl delete -k ./cloud/ocis/
kl delete -k ./cloud/ocis/ingress-wildcard/
kl delete -k ./cloud/ocis/pvc/
kl delete ns ocis
```
