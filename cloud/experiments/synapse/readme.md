
# Synapse

References:
- https://hub.docker.com/r/matrixdotorg/synapse
- https://medium.com/@sncr28/deploying-a-matrix-server-with-element-chat-in-docker-compose-with-nginx-reverse-proxy-cc9850fd32f8
- https://element-hq.github.io/synapse/latest/setup/installation.html#docker-images-and-ansible-playbooks


# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Config setup

```bash
public_url=my.matrix.host2
rm -r ./cloud/synapse/docker-mount/
docker run -it --rm \
  --volume ./cloud/synapse/docker-mount/:/data \
  -e SYNAPSE_SERVER_NAME=$public_url \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

# Deploy

```bash
kl create ns synapse
kl label ns synapse pod-security.kubernetes.io/enforce=baseline

# wildcard ingress
kl label ns --overwrite onlyoffice copy-wild-cert=main
kl apply -k ./cloud/synapse/ingress-wildcard/
kl -n synapse get ingress

kl apply -f ./cloud/synapse/postgres.yaml
kl -n synapse describe postgresqls.acid.zalan.do postgres
kl -n synapse get pod -o wide -L spilo-role

kl apply -k ./cloud/synapse/ingress-route/
kl -n synapse get httproute

kl apply -k ./cloud/synapse/
kl -n synapse get pod -o wide
```

# Cleanup

```bash
kl delete -k ./cloud/spacebar/main-app/
kl delete ns spacebar
```
