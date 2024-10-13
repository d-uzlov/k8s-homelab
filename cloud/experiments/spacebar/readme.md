
# Onlyoffice

References:
- https://spacebar.chat/
- https://docs.spacebar.chat/setup/server/#setup
- https://github.com/spacebarchat/docker
- https://hub.docker.com/r/spacebarchat/server

As of 2024-10-13, spacebar only has a web client,
which doesn't seem very good.

# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Config setup

Generate passwords and set up config.

```bash
mkdir -p ./cloud/onlyoffice/main-app/env/
cat <<EOF > ./cloud/onlyoffice/main-app/env/api.env
jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF

docker_username=
docker_repo=

docker build - < ./cloud/spacebar/Dockerfile -t docker.io/$docker_username/$docker_repo:spacebar-2024-10-13-v1
docker push docker.io/$docker_username/$docker_repo:spacebar-2024-10-13-v1
```

# Deploy

```bash
kl create ns spacebar
kl label ns spacebar pod-security.kubernetes.io/enforce=baseline

# wildcard ingress
kl label ns --overwrite onlyoffice copy-wild-cert=main
kl apply -k ./cloud/spacebar/ingress-wildcard/
kl -n spacebar get ingress

kl apply -f ./cloud/spacebar/postgres.yaml
kl -n spacebar describe postgresqls.acid.zalan.do postgres
kl -n spacebar get pod -o wide -L spilo-role

kl apply -k ./cloud/spacebar/ingress-route/
kl -n spacebar get httproute

kl apply -k ./cloud/spacebar/
kl -n spacebar get pod -o wide
```

# Cleanup

```bash
kl delete -k ./cloud/spacebar/main-app/
kl delete ns spacebar
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
