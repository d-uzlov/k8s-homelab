
# qBitTorrent

References:
- https://github.com/qbittorrent/docker-qbittorrent-nox/
- https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)
- https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox

# Storage setup

Set storage classes for different data types:

```bash
# list storage classes
kl get sc
# set values in env file
mkdir -p ./torrents/qbittorrent/pvc/env/
cat <<EOF > ./torrents/qbittorrent/pvc/env/pvc.env
# where qbittorrent internal configs should be located
config=bulk
config_size=1Gi
# .torrent files that user wants to download
watch=shared
watch_size=1Gi

# temporary folder for downloaded torrents
incomplete=bulk
incomplete_size=1Ti
# folder where torrents are moved after they are finished downloading
torrent=shared
torrent_size=10Ti
EOF
```

# Set up qBitTorrent config

qBitTorrent has a lot of settings.

Some settings are forced, like disabling UPnP (it wouldn't work in k8s either way),
some settings are configurable via this .env file,
some settings aren't important for running the app in the k8s
can only be changed via web-UI.

```bash
mkdir -p ./torrents/qbittorrent/main-app/env/
cat <<EOF > ./torrents/qbittorrent/main-app/env/settings.env
# set to true if you want to discard all changes in settings when the app is restarted
force_overwrite_config=false

# set to false if you want to download torrents in-place
enable_tmp_folder=true

# set to true to use username and password from this settings file
reset_password=false
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
kl label ns bt-qbittorrent pod-security.kubernetes.io/enforce=baseline

# set up storage, avoid deleting it
kl apply -k ./torrents/qbittorrent/pvc/
# make sure that PVCs are successfulyl provisioned
kl -n bt-qbittorrent get pvc

# create loadbalancer service
kl apply -k ./torrents/qbittorrent/loadbalancer/
# get assigned IP to set up DNS or NAT port-forwarding
kl -n bt-qbittorrent get svc
# Make sure that local port and external port match.
# Peers will try to connect to the port that qbittorrent is using locally.

# setup wildcard ingress
kl label ns --overwrite bt-qbittorrent copy-wild-cert=main
kl apply -k ./torrents/qbittorrent/ingress-wildcard/
kl -n bt-qbittorrent get ingress

# deploy main app
kl apply -k ./torrents/qbittorrent/main-app/
# make sure the pod is running
kl -n bt-qbittorrent get pod -o wide
```

# Cleanup

```bash
kl delete -k ./torrents/qbittorrent/main-app/
kl delete -k ./torrents/qbittorrent/ingress-wildcard/
kl delete -k ./torrents/qbittorrent/loadbalancer/
kl delete -k ./torrents/qbittorrent/pvc/
kl delete ns bt-qbittorrent
```

# Fix tags on existing torrents

```bash
qbt_domain=$(kl -n bt-qbittorrent get ingress qbittorrent -o go-template --template "{{ (index .spec.rules 0).host}}")
./torrents/qbittorrent/fix-tags.sh "$qbt_domain" /mnt/finished
```

# Alt web UI

Possible web UIs:
- https://github.com/erickok/transdroid (universal)
- https://github.com/CCExtractor/rutorrent-flutter (rutorrent)
- https://github.com/lgallard/qBittorrent-Controller (qbittorrent)

# Add trackers

- https://github.com/ngosang/trackerslist
