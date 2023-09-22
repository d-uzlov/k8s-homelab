
# Jellyfin

References:
- https://jellyfin.org/docs/general/installation/container
- https://hub.docker.com/r/jellyfin/jellyfin
- https://github.com/jellyfin/jellyfin

# Storage setup

```bash
# list storage classes
kl get sc
# set values in env file
mkdir -p ./video/jellyfin/pvc/env/
cat <<EOF > ./video/jellyfin/pvc/env/pvc.env
config=bulk
config_size=1Gi

torrent=shared
torrent_size=10Ti
EOF
```

# Deploy

```bash
kl create ns jellyfin

kl apply -k ./video/jellyfin/pvc/
kl -n jellyfin get pvc

kl apply -k ./video/jellyfin/
kl -n jellyfin get pod

# setup wildcard ingress
kl label ns --overwrite jellyfin copy-wild-cert=main
kl apply -k ./video/jellyfin/ingress-wildcard/
kl -n jellyfin get ingress
```
