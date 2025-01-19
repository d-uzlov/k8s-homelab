
# gotify

References:
- https://gotify.net/docs/install
- https://github.com/gotify/server/releases
- https://hub.docker.com/r/gotify/server/tags

# Generate config

```bash

mkdir -p ./metrics/gotify/env/
 cat << EOF > ./metrics/gotify/env/pvc-data.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  storageClassName: $storage_class
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
EOF

mkdir -p ./metrics/gotify/postgres/env/
 cat << EOF > ./metrics/gotify/postgres/env/postgres-patch.yaml
---
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: postgres
spec:
  volume:
    # 1Gi for WAL (default size)
    # 1Gi for database itself (seems to be fine for small instance)
    size: 2Gi
    storageClass: $storageClass
EOF

# admin password os saved in database, so it can not be changed via config after first successful start
 cat << EOF > ./metrics/gotify/env/admin-password.env
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

```

# Deploy

```bash

kl create ns gotify
kl label ns gotify pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/gotify/postgres/
kl apply -n gotify -f ./metrics/gotify/env/pvc-data.yaml
kl -n gotify get pvc
kl -n gotify describe postgresqls.acid.zalan.do postgres
kl -n gotify get pod -o wide -L spilo-role

postgres_password=$(kl -n gotify get secret gotify.postgres.credentials.postgresql.acid.zalan.do --template='{{.data.password | base64decode | printf "%s\n" }}')
 cat << EOF > ./metrics/gotify/env/postgres-connection.env
postgres_connection=host=postgres port=5432 user=gotify dbname=gotify password=$postgres_password
EOF

kl apply -k ./metrics/gotify/
kl -n gotify get pod -o wide -L spilo-role

kl apply -k ./metrics/gotify/httproute-public/
kl -n gotify get httproute
kl -n gotify describe httproute
```

# Cleanup

```bash
kl delete -k ./metrics/gotify/httproute-public/
kl delete -k ./metrics/gotify/
kl delete -n gotify -f ./metrics/gotify/env/pvc-data.yaml
kl delete -k ./metrics/gotify/postgres/
kl delete ns gotify
```

# OAuth2 / OIDC / SSO

Gotify doesn't support SSO and it doesn't seem like it will support it in foreseeable future:
- https://github.com/gotify/server/issues/203
