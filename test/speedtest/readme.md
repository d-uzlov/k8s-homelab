
https://github.com/e7d/speedtest

# Deploy

```bash
kl create ns speedtest
kl label ns --overwrite speedtest copy-wild-cert=main

# Init local settings
mkdir -p ./test/speedtest/env
cat <<EOF > ./test/speedtest/env/ingress.env
public_domain=speedtest.example.duckdns.org

wildcard_secret_name=main-wildcard-at-duckdns

allowed_sources=10.0.0.0/16,1.2.3.4
EOF

kl apply -k ./test/speedtest/
```

The test seems to show upload speed close to zero, regardless of settings.
