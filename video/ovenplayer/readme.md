
# OvenPlayer demo

This is a demo of how OvenPlayer can be integrated into a website.

However, if you don't have a website and don't care much about looks,
you can just use this demo as a main website.

References:
- https://hub.docker.com/r/airensoft/ovenplayerdemo
- https://github.com/AirenSoft/OvenPlayer

# Deploy

```bash
kl create ns ome-ovenplayer

# setup wildcard ingress
kl label ns --overwrite ome-player copy-wild-cert=main
kl apply -k ./video/ovenplayer/ingress-wildcard/
kl -n ome-ovenplayer get ingress

kl apply -k ./video/ovenplayer/
kl -n ome-ovenplayer get pod
```

# Cleanup

```bash
kl delete -k ./video/ovenplayer/
kl delete ns ome-ovenplayer
```

# Stream links

See [OvenMediaEngine documentation](../ome/) to see how to create stream links.
