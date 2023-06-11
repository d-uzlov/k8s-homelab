
# Deploy

```bash
# Init local settings
mkdir -p ./test/ingress/env/
cat <<EOF > ./test/ingress/env/ingress.env
public_domain=test-ingress.example.duckdns.org
EOF

kl apply -k ./test/ingress
```
