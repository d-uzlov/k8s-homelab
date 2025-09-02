
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
# the latest tag with proper web interface is RELEASE.2025-04-22T22-12-26Z
#   https://old.reddit.com/r/selfhosted/comments/1kva3pw/avoid_minio_developers_introduce_trojan_horse/
# but we don't really need web interface, cli is completely fine
minio_image=quay.io/minio/minio:RELEASE.2025-07-23T15-54-02Z

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

docker compose --project-directory ~/minio/ up -d
docker compose logs

# show admin credentials
cat ~/minio/.env

```

You can log in at `server-address:9001`.

If you want to use server for data storage, use `http://server-address:9000`.
Currently there is no setup for proper certificates.

# Cleanup

```bash
docker compose --project-directory ~/minio/ up -d
```

# Metrics

```bash

minio_address=$(mc alias export ${minio_alias} | jq -r .url)
minio_bearer_token=$(mc admin prometheus generate ${minio_alias} | grep bearer_token | sed -E 's/.*bearer_token: (.*)/\1/')

 cat << EOF > ./storage/minio/env/metrics-bearer.env
minio_bearer_token=$minio_bearer_token
EOF

# check metrics manually
curl -sS -H "Authorization: Bearer $minio_bearer_token" $minio_address/minio/metrics/v3 > ./minio-v3.log
curl -sS -H "Authorization: Bearer $minio_bearer_token" $minio_address/minio/metrics/v3/cluster > ./minio-v3-cluster.log
curl -sS -H "Authorization: Bearer $minio_bearer_token" $minio_address/minio/metrics/v3/cluster/usage > ./minio-v3-cluster-usage.log

cluster_name=
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
      location: $cluster_name
    targets:
    - $minio_address
  relabelings:
  - targetLabel: instance
    sourceLabels: [ __address__ ]
    regex: (.*):\d*
    action: replace
EOF

kl apply -f ./storage/minio/env/scrape-minio.yaml

```
