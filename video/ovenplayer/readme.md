
# OvenPlayer demo

https://github.com/AirenSoft/OvenPlayer

This is a demo of how OvenPlayer can be integrated into a website.

However, if you don't have a website and don't care much about looks,
you can just use this demo as a main website.

# Deploy

```bash
kl create ns ome-player
kl label ns --overwrite ome-player copy-wild-cert=main

kl apply -k ./video/ovenplayer/
```

# Stream links

See [OvenMediaEngine documentation](../ome/) to see how to create stream links.
