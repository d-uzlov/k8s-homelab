
# Vaultwarden

References:
- https://hub.docker.com/r/vaultwarden/server/tags
- https://github.com/Timshel/vaultwarden/blob/sso-support/SSO.md
- https://github.com/dani-garcia/vaultwarden/wiki/
- https://hub.docker.com/r/timshel/vaultwarden/tags

# Local setup

Set storage classes for different data types:

```bash
mkdir -p ./cloud/vaultwarden/postgres/env/
 cat << EOF > ./cloud/vaultwarden/postgres/env/postgres-patch.yaml
---
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: postgres
spec:
  volume:
    # 1Gi for WAL (default size)
    # 1Gi for database itself
    size: 2Gi
    storageClass: $storageClass
EOF

mkdir -p ./cloud/vaultwarden/pvc/env/
 cat << EOF > ./cloud/vaultwarden/pvc/env/pvc.env
data_storage_class=nfs
data_size=1Gi
EOF

mkdir -p ./cloud/vaultwarden/env/
 cat << EOF > ./cloud/vaultwarden/env/admin-token.env
admin_token=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 40)
EOF
# if you don't want to use SSO, you can also switch to the official docker image
# in the image I'm using you will always see a "login via SSO" button than will just show you an error
 cat << EOF > ./cloud/vaultwarden/env/sso.env
# true or false
sso_enable=false
# when false, you can choose how you login
# when true, login via master password will give you an error
force_sso=true
# authority in authentik: OpenID Configuration Issuer
# authority _must_ have / on the end
sso_authority=
client_id=
client_secret=
EOF

 cat << EOF > ./cloud/vaultwarden/env/config.env
# when registration is disabled, SSO auth will create account on login
# without SSO you can still create users in the admin interface
signups_allowed=false
EOF

```

# Deploy

```bash
kl create ns vaultwarden
kl label ns vaultwarden pod-security.kubernetes.io/enforce=baseline

kl apply -k ./cloud/vaultwarden/httproute-private/
kl apply -k ./cloud/vaultwarden/httproute-public/
kl -n vaultwarden get httproute

kl apply -k ./cloud/vaultwarden/pvc/
kl apply -k ./cloud/vaultwarden/postgres/
kl -n vaultwarden get pvc
kl -n vaultwarden describe postgresqls.acid.zalan.do postgres
kl -n vaultwarden get pod -o wide -L spilo-role

postgres_password=$(kl -n vaultwarden get secret vaultwarden.postgres.credentials.postgresql.acid.zalan.do --template='{{.data.password | base64decode | printf "%s\n" }}')
mkdir -p ./cloud/vaultwarden/env/
 cat << EOF > ./cloud/vaultwarden/env/postgres-url.env
pg_url=postgresql://vaultwarden:$postgres_password@postgres/vaultwarden
EOF
# choose which one you want to use
vaultwarden_public_domain=$(kl -n vaultwarden get httproute vaultwarden-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
vaultwarden_public_domain=$(kl -n vaultwarden get httproute vaultwarden-public -o go-template --template "{{ (index .spec.hostnames 0)}}")
 cat << EOF > ./cloud/vaultwarden/env/domain.env
domain=https://$vaultwarden_public_domain
EOF

kl apply -k ./cloud/vaultwarden/
kl -n vaultwarden get pod -o wide -L spilo-role

```

# Cleanup

```bash
kl delete -k ./cloud/vaultwarden/
kl delete -k ./cloud/vaultwarden/postgres/
kl delete -k ./cloud/vaultwarden/httproute-private/
kl delete -k ./cloud/vaultwarden/httproute-public/
kl delete ns vaultwarden
```

# Admin interface

You can access the vaultwarden admin interface via the `/admin` path:

```bash
vaultwarden_public_domain=$(kl -n vaultwarden get httproute vaultwarden-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
vaultwarden_public_domain=$(kl -n vaultwarden get httproute vaultwarden-public -o go-template --template "{{ (index .spec.hostnames 0)}}")
echo https://$vaultwarden_public_domain/admin
echo "token to access admin interface:"
(. ./cloud/vaultwarden/env/admin-token.env && echo $admin_token)
```
