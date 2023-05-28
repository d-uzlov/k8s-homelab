
https://github.com/ONLYOFFICE/DocumentServer
https://github.com/ONLYOFFICE/Docker-DocumentServer
https://github.com/ONLYOFFICE/docker-onlyoffice-nextcloud

# Deploy

```bash
kl create ns onlyoffice
kl label ns onlyoffice copy-wild-cert=example

# Init once
cat <<EOF > ./cloud/nextcloud/env/postrgesql.env
db_root_name=onlyoffice
db_root_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
db_name=onlyoffice
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/api.env
jwt_header=AuthorizationJwt
jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/public_domain.env
# host used in ingress
public_domain=onlyoffice.example.duckdns.org
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/settings.env
# set to value specified in ingress/manual-certificates/<your-cert>
wildcard_secret_name=wild--example.duckdns.org

# Limit access from web, or leave empty
# Comma-separated list of CIDRs
ingress_allowed_sources=10.0.0.0/16,1.2.3.4,1.2.3.4
EOF

kl apply -k ./cloud/onlyoffice/
```

# Error on nextcloud web-UI

Если документ просто не хочет открываться, хотя все работает — проблема может быть в сертификате.
Если открыть страницу onlyoffice и сказать браузеру доверять сертификату, то может помочь.

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
