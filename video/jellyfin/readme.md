
# Jellyfin

References:
- https://jellyfin.org/docs/general/installation/container
- https://hub.docker.com/r/jellyfin/jellyfin
- https://github.com/jellyfin/jellyfin
- https://github.com/jellyfin/jellyfin/releases

# Storage setup

```bash
# list storage classes
kl get sc
# set values in env file
mkdir -p ./video/jellyfin/pvc/base-env/env/
cat << EOF > ./video/jellyfin/pvc/base-env/env/pvc.env
# type: RWO
db_class=block
db_size=1Gi

# type: RWX
config_class=bulk
config_size=1Gi

# this deployment assumes that 'shared' storage class is shared between namespaces,
# and we use qbittorrent to populate it
# type: RWX
data_name=torrent
data_class=shared
data_size=10Ti

# type: RWX
links_class=bulk
links_size=1Gi
EOF
```

# Deploy

```bash
kl create ns jellyfin
kl label ns jellyfin pod-security.kubernetes.io/enforce=baseline

kl -n jellyfin apply -f ./network/network-policies/deny-ingress.yaml
kl -n jellyfin apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./video/jellyfin/pvc/
kl -n jellyfin get pvc

kl apply -k ./video/jellyfin/ingress-route/
kl -n jellyfin describe httproute
kl -n jellyfin get httproute

# setup wildcard ingress
kl label ns --overwrite jellyfin copy-wild-cert=main
kl apply -k ./video/jellyfin/ingress-wildcard/
kl -n jellyfin get ingress

# choose one:
#   generic doesn't have hardware acceleration
kl apply -k ./video/jellyfin/generic/
#   for intel GPUs
kl apply -k ./video/jellyfin/intel/
#   for nvidia GPUs
kl apply -k ./video/jellyfin/nvidia/

kl -n jellyfin get pod -o wide
```

# Cleanup

```bash
kl delete -k ./video/jellyfin/generic/
kl delete -k ./video/jellyfin/pvc/
kl delete ns jellyfin
```

# Links

Jellyfin expects a specific file/folder layout for the media files.
It's unlikely that you already have it,
and some other programs that you use may require a different layout.

So in this deployment we create a separate folder
in which you can place symlinks to your real files, which are mounted to `/raw-data/`.
This way you can completely redefine folder layout without touching the original files.

```bash
kl -n jellyfin exec deployments/jellyfin -it -- bash
# ln -s /path/to/file /path/to/symlink
ln -s /raw-data/video/ /media/video
```

# Enable hardware transcoding

By default hardware decoding and encoding is disabled.

You can go to `Dashboard` -> `Playback` to enable it.

VAAPI is a semi-universal API supported by both AMD and Intel but not by NVidia.

# Hardware acceleration on Intel GPUs

Prerequisites:
- [Intel device plugin](../../hardware/intel-device-plugin/readme.md)

Checking hardware capabilities (run on host):

```bash
sudo cat /sys/kernel/debug/dri/0/gt0/uc/guc_info
sudo cat /sys/kernel/debug/dri/0/gt0/uc/huc_info
```

References:
- https://jellyfin.org/docs/general/administration/hardware-acceleration/intel

# Hardware acceleration on NVidia GPUs

Prerequisites:
- [NVidia device plugin](../../hardware/nvidia-device-plugin/readme.md)

# Proper database support

Jellyfin uses SQLite and doesn't support remote databases.

But the support is coming soon™ (for about 3 years at the moment).

References:
- https://github.com/jellyfin/jellyfin/issues/42
- https://features.jellyfin.org/posts/315/mysql-server-back-end
- https://old.reddit.com/r/jellyfin/comments/y2ib5w/is_it_possible_to_use_jellyfin_with_a_remote/
