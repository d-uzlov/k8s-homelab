
# Minio

In this guide Minio is installed on a standalone Linux machine.

This is intended to be installed on your NAS linux system,
so that Minio has direct access to the filesystem.

# Install

Create a separate directory for Minio and create local configuration files there:

```bash

mkdir ~/minio/
cd ~/minio/

cat << EOF > ~/minio/.env
MINIO_ROOT_USER=root
MINIO_ROOT_PASSWORD=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

# create an empty directory for minio
minio_volume=/mnt/tulip/minio/
# get fresh image here: https://quay.io/repository/minio/minio?tab=tags
# alternatively: https://hub.docker.com/r/minio/minio/tags
minio_image=quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z

cat << EOF > ~/minio/docker-compose.yaml
services:
  minio:
    image: $minio_image
    command:
    - server
    - /data
    - --console-address=:9001
    ports:
    - 9000:9000
    - 9001:9001
    environment:
      MINIO_ROOT_USER: \${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: \${MINIO_ROOT_PASSWORD}
    volumes:
    - $minio_volume:/data
EOF

docker compose up -d
docker compose logs

# show admin credentials
cat ~/minio/.env

```

You can log in at `server-address:9001`.

If you want to use server for data storage, use `http://server-address:9000`.
Currently there is no setup for proper certificates.

# Cleanup

```bash
cd ~/minio/
docker compose up -d
```

# Metrics

Generate prometheus config.

Run this on the minio node

```bash

# minio is very stupid
# in the docker container they don't have auth by default
# if you tried to run `prometheus generate` without auth,
# you would get a token that doesn't have authorization to get metrics,
# and all requests would result in "Access denied"
. ~/minio/.env
docker compose exec minio mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
docker compose exec minio mc admin prometheus generate local

```

Run on the management machine.

```bash

# take bearer token from output of "mc admin prometheus generate"

minio_bearer_token=
minio_address=
cluster_name=

# check metrics manually
curl -sS -H "Authorization: Bearer $minio_bearer_token" http://$minio_address/minio/metrics/v3/cluster/usage > ./minio-v3-usage.log

minio_instance_name=
kl -n prometheus create secret generic minio-$minio_instance_name-bearer --from-literal minio-bearer=$minio_bearer_token

mkdir -p ./storage/minio/env/

 cat << EOF > ./storage/minio/env/scrape-minio.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-minio-$minio_instance_name
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  metricsPath: /minio/metrics/v3/cluster/usage
  authorization:
    type: Bearer
    credentials:
      name: minio-$minio_instance_name-bearer
      key: minio-bearer
  staticConfigs:
  - labels:
      job: minio
      cluster_type: minio
      cluster: $cluster_name
    targets:
    - $minio_address
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    action: replace
    sourceLabels: [ instance ]
    regex: (.*):\d*
EOF

kl apply -f ./storage/minio/env/scrape-minio.yaml

```
