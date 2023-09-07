
# qBitTorrent

https://github.com/qbittorrent/docker-qbittorrent-nox/

# Storage setup

Set storage classes for different data types:

```bash
# list storage classes
kl get sc
# set values in env file
mkdir -p ./torrents/qbittorrent/pvc/env/
cat <<EOF > ./torrents/qbittorrent/pvc/env/pvc.env
# where qbittorrent internal configs should be located
config=fast
# .torrent files that user wants to download
watch=shared

# temporary folder for downloaded torrents
incomplete=fast
# folder where torrents are moved after they are finished downloading
torrent=shared
EOF
```

# Set up qBitTorrent config

```bash
mkdir -p ./torrents/qbittorrent/env/
cat <<EOF > ./torrents/qbittorrent/env/settings.env
force_overwrite_config=true

# set to 'true' to use username and password from this settings file
reset_password=true
username=admin
# default password is 'adminadmin'
# if you want to change it, go to web UI, change it in settings,
# then copy value of WebUI\Password_PBKDF2
# from file /config/qBittorrent/config/qBittorrent-data.conf
password_encoded=@ByteArray(mF/Yn6wBmEW81W2xuMnlbw==:Z0N2dnsPfcgKP/57vZTFPyKr7nYRaxj2jON+4wrWH/ClVp7J3Xd6tz9Sje/oCqu/Y4+i/MmWrvqg/zVfZ6cQuA==)

# comma-separated CIDR list or empty
# When using with ingress, set to pod CIDR from your CNI settings.
trusted_proxies=10.201.0.0/16

# comma-separated CIDR list of source addresses
# that can open the web-ui without password.
# For example: 10.0.0.0/16,1.2.3.4/32
#
# At the very least it should contain k8s pod network, to allow k8s to perform liveness check
# or else k8s will constantly restart the app, and ingress will be unavailable.
#
# Set to your LAN CIDR for passwordless access in LAN.
# Set to your public IP for passwordless access via NAT loopback.
auth_whitelist=10.201.0.0/16
EOF
```

# Deploy

```bash
kl create ns bt-qbittorrent

# create loadbalancer service
kl apply -k ./torrents/qbittorrent/loadbalancer/
# get assigned IP to set up DNS or NAT port-forwarding
kl -n bt-qbittorrent get svc
# Make sure that local port and external port match.
# Peers will try to connect to the port that qbittorrent is using locally.

# set up storage, avoid deleting it
kl apply -k ./torrents/qbittorrent/pvc/
# make sure that PVCs are successfulyl allocated
kl -n bt-qbittorrent get pvc

# deploy main app
kl apply -k ./torrents/qbittorrent/
# make sure the pod is running
kl -n bt-qbittorrent get pod

# setup wildcard ingress
kl label ns --overwrite bt-qbittorrent copy-wild-cert=main
kl apply -k ./torrents/qbittorrent/ingress-wildcard/
kl -n bt-qbittorrent get ingress
```

# Alt web UI

Possible web UIs:
https://github.com/erickok/transdroid (universal)
https://github.com/CCExtractor/rutorrent-flutter (rutorrent)
https://github.com/lgallard/qBittorrent-Controller (qbittorrent)

# Add trackers

https://github.com/ngosang/trackerslist
