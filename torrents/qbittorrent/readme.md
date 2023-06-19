
https://github.com/qbittorrent/docker-qbittorrent-nox/

# Deploy

Init local settings:
```bash
mkdir -p ./torrents/qbittorrent/env/
cat <<EOF > ./torrents/qbittorrent/env/ingress.env
public_domain=qbittorrent.example.duckdns.org

wildcard_secret_name=main-wildcard-at-duckdns

allowed_sources=10.0.0.0/16,1.2.3.4
EOF
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
# At the very least it should contain main IP of the node
# where qBittorrent will be running
# or else k8s will not be able to perform liveness check and will constantly restart the app.
#
# Set to your LAN CIDR for passwordless access in LAN.
# Set to your public IP for passwordless access via NAT loopback.
auth_whitelist=
EOF
```

Deploy:
```bash
kl create ns bt-qbittorrent
kl label ns --overwrite bt-qbittorrent copy-wild-cert=main

kl apply -k ./torrents/qbittorrent/pvc

kl apply -k ./torrents/qbittorrent/
```

Set up port forwarding for torrent data.
Check service description to learn load balancer IP and port.

Make sure that local port and external port match.
Peers will try to connect to the port that qbittorrent is using locally.

# Alt web UI

Possible web UIs:
https://github.com/erickok/transdroid (universal)
https://github.com/CCExtractor/rutorrent-flutter (rutorrent)
https://github.com/lgallard/qBittorrent-Controller (qbittorrent)

# Add trackers

https://github.com/ngosang/trackerslist
