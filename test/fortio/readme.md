
# Deploy

```bash
kl create ns fortio
kl label ns --overwrite fortio copy-wild-cert=main

# Init local settings
mkdir -p ./test/fortio/env
cat <<EOF > ./test/fortio/env/ingress.env
public_domain=fortio.example.duckdns.org

wildcard_secret_name=main-wildcard-at-duckdns

allowed_sources=10.0.0.0/16,1.2.3.4
EOF

kl apply -k ./test/fortio/
```
