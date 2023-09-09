
# Manual certificates

When using LetsEncrypt there are generally 2 ways of assigning a certificate for your ingress:
- Annotate the ingress to create a special certificate just for this domain
- Create single a wildcard certificate and use it for all subdomains

This folder contains an example how you can create a wildcard certificate for the second approach.

# Init local info

```bash
mkdir -p ./ingress/manual-wildcard/domain-info/env/
cat <<EOF > ./ingress/manual-wildcard/domain-info/env/domain.env
# your subdomain name registered at the duckdns website
# if you domain is 'example.duckdns.org',
# then place 'example' here
subdomain=example

# secret name that ingress resources will be using
# can be anything, just make sure that you don't use this name for other secrets
secret_name=main-wildcard

# label for the certificate secret
# used by the 'replicator' deployment
copy_label=copy-wild-cert=main
EOF
```

# Test on staging environment

First deploy a staging certificate to test if everything works.
Staging servers have generous limits,
so you won't lock yourself out of letsencrypt on accident.

```bash
kl create ns cm-manual

kl apply -k ./ingress/manual-wildcard/staging

# you can check the following resources to see if everything goes as expected
kl -n cm-manual get certificate
kl -n cm-manual get certificaterequests.cert-manager.io
kl -n cm-manual get orders.acme.cert-manager.io

# Note that it can take LetsEncrypt several minutes to verify DNS-01 challenge and give you the certificate.

# delete staging certificate after it is was successfully issued
kl delete -k ./ingress/manual-wildcard/staging
# if we don't delete secret, then when we re-deploy the certificate,
# cert-manager will see that secret already exists and skip re-issuing the certificate
kl -n cm-manual delete secrets main-wildcard
```

If the certificate doesn't get approved for too long, you can check the following resources for debugging:

```bash
# or use describe on the same resources
kl -n cm-manual describe certificate
kl -n cm-manual describe certificaterequests.cert-manager.io
kl -n cm-manual describe orders.acme.cert-manager.io

# check if duckdns webhook have any errors
kl -n cm-duckdns logs deployments/duckdns-webhook --tail 20
# check if cert-manager have any errors
kl -n cert-manager logs deployments/cert-manager --tail 20
# replace with your domain to check if the webhook
# at least set up the TXT record for DNS-01 challenge
nslookup -q=txt example.duckdns.org
```

# Create production certificate

After you verified that your setup works
you can re-issue a proper production certificate:

```bash
kl apply -k ./ingress/manual-wildcard/production

kl -n cm-manual get certificate
```

# Avoid re-creating production certificate when re-creating cluster

You can save the certificate and deploy it in the new cluster,
without requesting a new certificate from ACME provider.

```bash
# save
mkdir -p ./ingress/manual-wildcard/env/
kl -n cm-manual get secrets main-wildcard -o yaml > ./ingress/manual-wildcard/env/wildcard-secret.yaml

# restore
kl apply -f ./ingress/manual-wildcard/env/wildcard-secret.yaml
```

# Using in ingress resources

Ingress resources need certificate in the same namespace.

Easy way to copy certificate to each required namespace is to use [replicator](../replicator/readme.md).

After deployment use `copy_label` from `domain.env`
as a label for namespace where you need to use the certificate.

You also need to adjust ingress spec:
- Remove issuer annotation.
- Set `spec.tls[].secretName` to match secret name from certificate spec.
