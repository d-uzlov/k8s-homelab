
# Onlyoffice

References:
- https://github.com/ONLYOFFICE/DocumentServer
- https://github.com/ONLYOFFICE/Docker-DocumentServer
- https://github.com/ONLYOFFICE/docker-onlyoffice-nextcloud
- https://hub.docker.com/r/onlyoffice/documentserver/
- https://hub.docker.com/_/rabbitmq

# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Config setup

Generate passwords and set up config.

```bash

mkdir -p ./cloud/onlyoffice/main-app/env/
 cat << EOF > ./cloud/onlyoffice/main-app/env/api.env
jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF

mkdir -p ./cloud/onlyoffice/postgres/env/
 cat << EOF > ./cloud/onlyoffice/postgres/env/postgres-patch.yaml
---
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: postgres
spec:
  volume:
    # 1Gi for WAL (default size)
    # 1Gi for database itself (seems to be fine for small nextcloud instance)
    size: 2Gi
    storageClass: $storageClass
EOF

```

# Deploy

```bash

kl create ns onlyoffice
kl label ns onlyoffice pod-security.kubernetes.io/enforce=baseline

# wildcard ingress
kl label ns --overwrite onlyoffice copy-wild-cert=main
kl apply -k ./cloud/onlyoffice/ingress-wildcard/
kl -n onlyoffice get ingress

kl apply -k ./cloud/onlyoffice/httproute-public/
kl -n onlyoffice get httproute

# kl apply -k ./cloud/onlyoffice/postgres/
# kl -n onlyoffice get pvc
# kl -n onlyoffice describe postgresqls.acid.zalan.do postgres
# kl -n onlyoffice get pod -o wide -L spilo-role

kl apply -k ./cloud/onlyoffice/postgres-cnpg/
kl -n onlyoffice get cluster
kl -n onlyoffice describe cluster postgres
kl -n onlyoffice get pvc
kl -n onlyoffice get pods -o wide -L role -L cnpg.io/jobRole
kl -n onlyoffice get svc
kl -n onlyoffice get secrets
kl cnpg -n onlyoffice status postgres

kl apply -k ./cloud/onlyoffice/main-app/
kl -n onlyoffice get pod -o wide

```

# Cleanup

```bash
kl delete -k ./cloud/onlyoffice/main-app/
kl delete ns onlyoffice
```

# Note on certificates

If you are using a staging certificate for onlyoffice,
you may have troubles accessing it via nextcloud interface.

Usually browsers ask you if trust staging certificate.
But when you open an onlyoffice frame inside nextcloud page
the browser doesn't have a chance to ask you,
so the download silently fails.

A workaround is to open onlyoffice page directly and accept the certificate.

# Run scripts

Useful for debugging.

```bash

cat /usr/bin/documentserver-prepare4shutdown.sh
cat /app/ds/run-document-server.sh
cat /usr/bin/documentserver-generate-allfonts.sh

```

# Custom fonts

```yaml
        volumeMounts:
        - mountPath: /usr/share/fonts/truetype/custom
          name: fonts
      volumes:
      - name: fonts
        persistentVolumeClaim:
          claimName: fonts-nfs
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: fonts-nfs
spec:
  storageClassName: nfs-ssd-tmp
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

References:
- https://helpcenter.onlyoffice.com/installation/docs-community-install-fonts-linux.aspx
