
# Manual certificates

This folder just contains a short way to create manually created certificates.

Usually certificates are created automatically on demand
but when using a wildcard certificate you should create one manually,
because you don't need to make more than one.

# !!! Warning !!!

This deployment uses letsencrypt-production issuer.

If anything goes wrong, you may exhaust letsencrypt limits
and lock yourself out of its certificates for a week.

When deploying first time manually change it to staging issuer and check that it works.
Then change it back to use a properly-signed certificate.

# Deploy

```bash
# Init once
mkdir -p ./ingress/manual-certificates/env
echo <<EOF > ./ingress/manual-certificates/env/domain.env
# your domain name registered on duckdns website
domain=example.duckdns.org
# same domain name, with a wildcard
domain_wildcard=*.example.duckdns.org
# secret name that ingress resources will be using
secret_name=wild-example.duckdns.org
# label for the certificate secret
# used by `replicator` deployment
copy_label=copy-wild-cert=example
EOF

kl create ns certificates
kl apply -k ./ingress/manual-certificates
```

# Using in ingress resources

Ingress resources need certificate in the same namespace.

Easy way to copy certificate to each required namespace is to use [replicator](../replicator/).

After deployment use `copy_label` from `domain.env`
as a label for namespace where you need to use the certificate.

You also need to adjust ingress spec:
- Remove issuer annotation.
- Set `spec.tls[].secretName` to match secret name from certificate spec.

