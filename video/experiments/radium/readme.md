
# Radium

https://github.com/zibbp/radium/tree/next

This is supposed to be a somewhat functional online player for OME streams.

This deployment uses `next` branch from the repo, because master branch doesn't suport OME.

The app requres you to pin the stream URL before deploying it.
There is a chat on the page. It isn't very functional:
history is not availabla, security is not available, emotes seem to be partially broken.

However, the `next` branch seems to lack features
compared to description in master branch, and the project seems to be abandoned.

# Deploy

```bash
kl create ns radium
kl label ns --overwrite radium copy-wild-cert=main

# Init once
cat <<EOF > ./torrents/qbittorrent/env/ingress.env
public_domain=radium.example.duckdns.org
public_link=https://radium.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,37.192.43.30

source_irl=wss://ome-signal.example.duckdns.org/app/stream-name
EOF
```
