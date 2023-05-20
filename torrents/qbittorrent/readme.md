
https://github.com/qbittorrent/docker-qbittorrent-nox/

# Deploy

```bash
kl create ns bt-qbittorrent
kl label ns bt-qbittorrent copy-wild-cert=example

kl apply -k ./torrents/qbittorrent/pvc

# Init local settings
cat <<EOF > ./torrents/qbittorrent/env/ingress.env
public_domain=qbittorrent.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,1.2.3.4
EOF
# Init local settings
cat <<EOF > ./torrents/qbittorrent/env/settings.env
username=admin

# default password is adminadmin
# if you want to change it, go to web UI, change it is settings,
# then copy value of WebUI\Password_PBKDF2
# from file /config/qBittorrent/config/qBittorrent-data.conf
password_encoded=

# comma-separated CIDR list or empty
# For example: 10.201.0.0/16
trusted_proxies=

# comma-separated CIDR list or empty
# For example: 10.0.0.0/16, 1.2.3.4/32
auth_whitelist=
EOF

kl apply -k ./torrents/qbittorrent/
```

Set up port forwarding for torrent data.
Check service description to learn load balancer ip and port.

Default username/password is admin/adminadmin

# Replicas

qbittorrent locks a file in the config folder on startup.
If the file is already locked, it exits.
Therefore, it's impossible to run 2 instances with the same config folder.

One side effect of this is that RollingUpdate doesn't work.
Also, if you delete a pod manually, it also holds the lock until it properly exits.
Meanwhile, the new pod restarts in a cycle.

# Alt web UI

Posible web UIs:
https://github.com/erickok/transdroid (universal)
https://github.com/CCExtractor/rutorrent-flutter (rutorrent)
https://github.com/lgallard/qBittorrent-Controller (qbittorrent)

# TODO

https://github.com/usma0118/magnet2torrent
