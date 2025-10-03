
# Authelia

References:
- https://www.authelia.com/integration/kubernetes/chart/

Authelia needs an LDAP backend.
I didn't find a good LDAP provider with high availability.

# Generate config

You only need to do this when updating the app.

```bash
helm repo add authelia https://charts.authelia.com
helm repo update authelia
helm search repo authelia/authelia --versions --devel | head
helm show values authelia/authelia --version 0.10.46 > ./auth/authelia/default-values.yaml
```

```bash

helm template \
  authelia \
  authelia/authelia \
  --version 0.10.46 \
  --namespace authelia \
  --values ./auth/authelia/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/authelia/authelia.gen.yaml

```

# config

```bash

mkdir -p ./auth/authelia/env/

 cat << EOF > ./auth/authelia/env/authelia-secret.env
storage.encryption_key=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 64)
session.secret=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 64)
identity_validation.reset_password.jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 64)
identity_providers.oidc.hmac_secret=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 64)
EOF

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ./auth/authelia/env/jwks_key

# get ldap connection credentials from your ldap server

 cat << EOF > ./auth/authelia/env/ldap-auth.env
user=UID=admin,OU=people,DC=example,DC=com
password=
EOF

 cat << EOF > ./auth/authelia/env/domain.env
# domain is used for browser cookies
domain=authelia.example.com
# name is used for TOTP default name
name=example dot com
EOF

mkdir -p ./auth/authelia/dragonfly/env/

 cat << EOF > ./auth/authelia/dragonfly/env/password.env
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 32)
EOF

kl get sc
storage_class=
sed "s/storageClassName: REPLACE_ME/storageClassName: $storage_class/" ./auth/authelia/dragonfly/dragonfly-authelia.template.yaml > ./auth/authelia/dragonfly/env/dragonfly-authelia.yaml

touch ./auth/authelia/config/env/10_oidc_clients.yaml
touch ./auth/authelia/config/env/03_ldap_attributes.yaml
[ -f ./auth/authelia/config/env/01_notifications.yaml ] || cp ./auth/authelia/config/01_notifications-filesystem.yaml ./auth/authelia/config/env/01_notifications.yaml

```

# Deploy

Prerequisites:
- [ldap](../lldap/readme.md)
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

```bash

kl create ns auth-authelia
kl label ns auth-authelia pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/authelia/dragonfly/
kl -n auth-authelia get dragonfly
kl -n auth-authelia get pod -o wide -L role
kl -n auth-authelia get pvc
kl -n auth-authelia get svc

kl apply -k ./auth/authelia/httproute-private/
kl apply -k ./auth/authelia/httproute-public/
kl -n auth-authelia get htr

kl apply -k ./auth/authelia/
kl -n auth-authelia get pod -o wide

kl -n auth-authelia logs deployments/authelia --tail 30
kl -n auth-authelia logs deployments/authelia --follow > ./authelia.log

```

Authelia doesn't have its own user management, it delegates it to the LDAP server.
For example, you can use LDAP admin credentials to test login.

Authelia devs are very cocky about their _security_, and authelia tries to be fully _spec-compliant_,
aka it's very painful to use.
It's the most obnoxious SSO I have ever worked with.

For example, you can't just specify client secret, you need to put hash of the secret.
You can't just have a proper ID token, ID token contains only bare minimum info,
and you need to query UserInfo endpoint for anything useful.

# Cleanup

```bash
kl delete -k ./auth/authelia/
kl delete -k ./auth/authelia/dragonfly/
kl delete -k ./auth/authelia/postgres-cnpg/
kl delete ns authelia
```

# clients

```bash

# generate new client secret
docker run --rm ghcr.io/authelia/authelia:4.39.6 authelia crypto hash generate pbkdf2 --variant sha512 --random --random.charset rfc3986

# authelia has single issuer URL for all projects/apps
# issuer URL
echo https://$(kl -n auth-authelia get httproute authelia-public -o go-template --template "{{ (index .spec.hostnames 0)}}")
# discovery URL
echo https://$(kl -n auth-authelia get httproute authelia-public -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration
curl https://$(kl -n auth-authelia get httproute authelia-public -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration | jq

```
