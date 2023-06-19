
https://github.com/openspeedtest/Docker-Image

# Deploy

```bash
kl create ns openspeedtest
kl label ns --overwrite openspeedtest copy-wild-cert=main

# Init local settings
mkdir -p ./test/openspeedtest/env
cat <<EOF > ./test/openspeedtest/env/ingress.env
public_domain=openspeedtest.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,1.2.3.4
EOF

kl apply -k ./test/openspeedtest/
```

This test seems to show unlimited upload speed for some reason.
For example: DL 950, UL 120000, while the physical network is 1 GBit/s.

Also it seems to automatically upload results to `openspeedtest.com`.
