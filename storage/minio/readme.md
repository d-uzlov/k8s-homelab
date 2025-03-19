
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
minio_image=quay.io/minio/minio:RELEASE.2025-03-12T18-04-18Z

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
