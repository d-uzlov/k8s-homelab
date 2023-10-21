
https://github.com/usma0118/magnet2torrent

# Deploy

```bash
kl create ns bt-m2t
kl label ns --overwrite bt-m2t copy-wild-cert=main

kl apply -k ./torrents/m2t
```
