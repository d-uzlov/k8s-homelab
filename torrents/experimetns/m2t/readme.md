
https://github.com/usma0118/magnet2torrent

# Deploy

```bash
kl create ns bt-m2t
kl label ns bt-m2t copy-wild-cert=example

kl apply -k ./torrents/m2t
```
