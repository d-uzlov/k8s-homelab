
# Authentik

Authentik is an identity provider.
It can be used to do unified auth across many applications.
It can also be used as a proxy, adding auth to simple applications that don't have it on its own.

References:
- https://goauthentik.io/#comparison
- https://xpufx.com/posts/protecting-your-first-app-with-authentik/
- https://medium.com/@wessel__/istio-with-authentik-securing-your-cluster-and-providing-authentication-and-authorization-b5e48b331920

# Generate config

You only need to do this when updating the app.

```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update authentik
helm search repo authentik/authentik --versions --devel | head
helm show values authentik/authentik --version 2025.4.1 > ./auth/authentik/default-values.yaml
```

```bash

# https://hub.docker.com/r/bitnamicharts/redis/tags
helm show values oci://registry-1.docker.io/bitnamicharts/redis --version 20.6.2 > ./auth/authentik/redis-default-values.yaml

helm template \
  authentik \
  authentik/authentik \
  --version 2025.4.1 \
  --namespace authentik \
  --values ./auth/authentik/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./auth/authentik/authentik.gen.yaml

helm template \
  redis \
  oci://registry-1.docker.io/bitnamicharts/redis \
  --version 20.6.2 \
  --namespace authentik \
  --values ./auth/authentik/db/redis-values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e 's/redis-data/data/' \
  > ./auth/authentik/db/redis.gen.yaml

```

# Deploy

Generate passwords and set up config.

```bash

mkdir -p ./auth/authentik/db/env/
 cat << EOF > ./auth/authentik/db/env/redis-password.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
 cat << EOF > ./auth/authentik/db/env/redis-sc.env
# authentik keeps session info in redis, so we need PVC for to avoid resetting sessions on restart
redis_storage_class=nvmeof
EOF
 cat << EOF > ./auth/authentik/db/env/postgres-sc.env
postgres_storage_class=nvmeof
EOF

mkdir -p ./auth/authentik/env/
 cat << EOF > ./auth/authentik/env/authentik-seed.env
# Secret key used for cookie signing. Changing this will invalidate active sessions.
# Prior to 2023.6.0 the secret key was also used for unique user IDs.
# When running a pre-2023.6.0 version of authentik the key should not be changed after the first install.
authentik_seed=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

# consult your email provider for info how to connect to smtp
# if you don't want to use it, leave everything empty
# for example:
# - yandex: https://yandex.ru/support/yandex-360/customers/mail/ru/mail-clients/others.html#smtpsetting
# - google: https://support.google.com/a/answer/176600?hl=en
 cat << EOF > ./auth/authentik/env/authentik-smtp.env
auth_smtp_host=AUTOREPLACE_SMTP_HOST
auth_smtp_port=AUTOREPLACE_SMTP_PORT
auth_smtp_username=AUTOREPLACE_SMTP_USERNAME
auth_smtp_password=AUTOREPLACE_SMTP_PASSWORD
auth_smtp_use_tls=false
auth_smtp_use_ssl=true
# example: "Authentik <user@example.com>"
auth_smtp_from="AUTOREPLACE_SMTP_FROM"
EOF

```

```bash

kl create ns authentik
kl label ns authentik pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/authentik/db/
kl -n authentik get postgresql
kl -n authentik get pvc
kl -n authentik get pod -o wide -L spilo-role

authentik_seed=$(. ./auth/authentik/env/authentik-seed.env; echo $authentik_seed)
redis_password=$(. ./auth/authentik/db/env/redis-password.env; echo $redis_password)
postgres_password=$(kl -n authentik get secret authentik.postgres.credentials.postgresql.acid.zalan.do --template='{{.data.password | base64decode | printf "%s\n" }}')
 cat << EOF > ./auth/authentik/env/authentik-passwords-patch.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: authentik
stringData:
  AUTHENTIK_POSTGRESQL__PASSWORD: $postgres_password
  AUTHENTIK_REDIS__PASSWORD: $redis_password
  AUTHENTIK_SECRET_KEY: $authentik_seed
EOF
 ( . ./auth/authentik/env/authentik-smtp.env;
 cat << EOF > ./auth/authentik/env/authentik-smtp-patch.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: authentik
stringData:
  AUTHENTIK_EMAIL__FROM: $auth_smtp_from
  AUTHENTIK_EMAIL__HOST: $auth_smtp_host
  AUTHENTIK_EMAIL__PASSWORD: $auth_smtp_password
  AUTHENTIK_EMAIL__PORT: '$auth_smtp_port'
  AUTHENTIK_EMAIL__USE_SSL: '$auth_smtp_use_ssl'
  AUTHENTIK_EMAIL__USE_TLS: '$auth_smtp_use_tls'
  AUTHENTIK_EMAIL__USERNAME: $auth_smtp_username
EOF
)

kl apply -k ./auth/authentik/
kl -n authentik get pod -o wide -L spilo-role

kl apply -k ./auth/authentik/httproute-private/
kl -n authentik get httproute

# go here to set up access
echo "https://"$(kl -n authentik get httproute authentik-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/if/flow/initial-setup/
# after you finished the initial setup, it's safe to open public access to authentik
kl apply -k ./auth/authentik/httproute-public/
kl -n authentik get httproute

```

# Cleanup

```bash
kl delete -k ./auth/authentik/
kl delete ns authentik
```

# Additional configuration

- [General tips](./tips.md)
- [Auth proxy for applications that don't support auth natively](./proxy.md)
- [Customize auth options and appearance](./flow-configuration.md)
