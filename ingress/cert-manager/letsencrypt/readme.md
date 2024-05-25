
# LetsEncrypt

This deployment just adds LetsEncrypt issuers to the cluster.

These issuers use HTTP-01 challenge:
- They are fully automatic, no additional config needed
- They need port 80 to be opened in the ingress.
- They must point to exact domain name, wildcard certificates are not supported

# Deploy

```bash
# Init once
mkdir -p ./ingress/cert-manager/letsencrypt/env/
echo <<EOF > ./ingress/cert-manager/letsencrypt/env/letsencrypt.env
# Can be any valid email.
# Letsencrypt will send you a warning on this address
# a few days before any of your certificates expire.
email=example@example.com
EOF

kl apply -k ./ingress/cert-manager/letsencrypt/
```
