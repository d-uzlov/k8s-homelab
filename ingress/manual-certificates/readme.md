
# Manual certificates

When using LetsEncrypt there are generally 2 ways of assigning a certificate for your ingress:
- Annotate the ingress to create a special certificate just for this domain
- Create single a wildcard certificate and use it for all subdomains

This folder contains an example how you can create a wildcard certificate for the second approach.

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
cat <<EOF > ./ingress/manual-certificates/env/domain.env
# your domain name registered on the duckdns website
domain=example.duckdns.org
# same domain name, with a wildcard
domain_wildcard=*.example.duckdns.org
# secret name that ingress resources will be using
secret_name=main-wildcard-at-duckdns
# label for the certificate secret
# used by the 'replicator' deployment
copy_label=copy-wild-cert=main
EOF

kl create ns cm-manual
kl apply -k ./ingress/manual-certificates/staging

# you can check the following resources to see if everything goes as expected
kl -n cm-manual get certificate
kl -n cm-manual get certificaterequests.cert-manager.io
kl -n cm-manual get orders.acme.cert-manager.io

kl -n cm-duckdns logs deployments/duckdns-webhook
# replace with your domain to check if the webhook
# at least set up the TXT record for DNS-01 challenge
nslookup -q=txt example.duckdns.org

kl -n cm-manual describe certificate
kl -n cm-manual describe certificaterequests.cert-manager.io
kl -n cm-manual describe orders.acme.cert-manager.io

# after you verified that your setup works
# re-issue a proper production certificate
kl -n cm-manual delete certificate main-wildcard-at-duckdns
kl apply -k ./ingress/manual-certificates/production
```

Note that it can take LetsEncrypt several minutes to verify DNS-01 challenge and give you the certificate.

# Using in ingress resources

Ingress resources need certificate in the same namespace.

Easy way to copy certificate to each required namespace is to use [replicator](../replicator/).

After deployment use `copy_label` from `domain.env`
as a label for namespace where you need to use the certificate.

You also need to adjust ingress spec:
- Remove issuer annotation.
- Set `spec.tls[].secretName` to match secret name from certificate spec.
