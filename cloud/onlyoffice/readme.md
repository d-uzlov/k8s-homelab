
# Onlyoffice

References:
- https://github.com/ONLYOFFICE/DocumentServer
- https://github.com/ONLYOFFICE/Docker-DocumentServer
- https://github.com/ONLYOFFICE/docker-onlyoffice-nextcloud
- https://hub.docker.com/r/onlyoffice/documentserver/
- https://hub.docker.com/_/postgres
- https://hub.docker.com/_/rabbitmq

# Storage setup

```bash
mkdir -p ./cloud/onlyoffice/pvc/env/
cat <<EOF > ./cloud/onlyoffice/pvc/env/pvc.env
postgresql=block
postgresql_size=1Gi
EOF
```

# Config setup

Generate passwords and set up config.

```bash
mkdir -p ./cloud/onlyoffice/main-app/env/
cat <<EOF > ./cloud/onlyoffice/main-app/env/postrgesql.env
db_root_name=onlyoffice
db_root_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
db_name=onlyoffice
EOF
cat <<EOF > ./cloud/onlyoffice/main-app/env/api.env
jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
```

# Deploy

```bash
kl create ns onlyoffice

# wildcard ingress
kl label ns --overwrite onlyoffice copy-wild-cert=main
kl apply -k ./cloud/onlyoffice/ingress-wildcard/
kl -n onlyoffice get ingress

kl apply -k ./cloud/onlyoffice/pvc/
kl -n onlyoffice get pvc

kl apply -k ./cloud/onlyoffice/main-app/
kl -n onlyoffice get pod -o wide
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
        - name: fonts
          mountPath: /usr/share/fonts/truetype/custom
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
