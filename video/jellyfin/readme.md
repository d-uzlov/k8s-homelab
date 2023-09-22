
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

# Checking hardware capabilities on intel

```bash
sudo cat /sys/kernel/debug/dri/0/gt0/uc/guc_info
sudo cat /sys/kernel/debug/dri/0/gt0/uc/huc_info
```

# Enable hardware transcoding

By default hardware decoding and encoding is disabled.

You can go to `Dashboard` -> `Playback` to enable it.

VAAPI is a semi-universal API supported by both AMD and Intel but not by NVidia.
