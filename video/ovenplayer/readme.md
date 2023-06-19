
# OvenPlayer demo

https://github.com/AirenSoft/OvenPlayer

This is a demo of how OvenPlayer can be integrates into a website.

However, if you don't have a website and don't care much about looks,
you can just use this demo as a main website.

# Deploy

```bash
kl create ns ome-player
kl label ns --overwrite ome-player copy-wild-cert=main

# Init once
mkdir -p ./streaming/ovenplayer/env
cat <<EOF > ./streaming/ovenplayer/env/ingress.env
public_domain=ome-player.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,1.2.3.4
EOF

kl apply -k ./streaming/ovenplayer/
```

# Stream links

See [OvenMediaEngine documentation](../ome/) to see how to create stream links.
