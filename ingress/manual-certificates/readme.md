
# Manual certificates

When using LetsEncrypt there are generally 2 ways of assigning a certificate for your ingress:
- Annotate the ingress to create a special certificate just for this domain
- Create single a wildcard certificate and use it for all subdomains

This folder contains an example how you can create a wildcard certificate for the second approach.

# Create certificate from template

This is a general template for certificates that I consider a good practice.

You can create several certificates, but only one
will be treated as the main one by this repo,
with automatic ingress replacements.

```bash

domain_name=my-domain.parent-domain.com
# either ClusterIssuer or Issuer
issuer_kind=Issuer
# look up available issuers
kl get clusterissuer
kl get issuer -A
# $domain_name is used by acme-dns in /ingress/cert-manager/acme-dns/readme.md
# for other issuers fill issuer_prefix manually
issuer_prefix=$domain_name

mkdir -p ./ingress/manual-certificates/env/
# if you don't need the wildcard domain, remove it manually
# remember that you _have_ to remove if when using HTTP01 challenge

 cat << EOF > ./ingress/manual-certificates/env/$domain_name-cert-staging.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $domain_name-staging
spec:
  issuerRef:
    kind: $issuer_kind
    name: $issuer_prefix-staging
  # shown in the cert info, doesn't seem to do anything else
  commonName: $domain_name
  dnsNames:
  - $domain_name
  - '*.$domain_name'
  secretName: cert-$domain_name-staging
EOF
# add annotations that allow you to copy this certificate automatically between namespaces
# useful for classic k8s ingress
# you don't need it for gateway API
replicator_label=copy-wild-cert=main
 cat << EOF >> ./ingress/manual-certificates/env/$domain_name-cert-staging.yaml
  secretTemplate:
    annotations:
      replicator.v1.mittwald.de/replicate-to-matching: >
        $replicator_label
EOF

sed ./ingress/manual-certificates/env/$domain_name-cert-staging.yaml \
  -e 's/-staging/-production/g' \
  > ./ingress/manual-certificates/env/$domain_name-cert-production.yaml

```

Save environment info to automate ingress deployment:

```bash

mkdir -p ./ingress/manual-certificates/domain-info/env/
 cat << EOF > ./ingress/manual-certificates/domain-info/env/main-domain.env
# used to deploy environment-agnostic ingress
domain_suffix=$domain_name
secret_name=cert-$domain_name-production
EOF

 cat << EOF > ./ingress/manual-certificates/domain-info/env/main-domain-replicator.env
# label for the certificate secret
# used by the 'replicator' deployment
# this is just so you don't forget the value
copy_label=$replicator_label
EOF

```

If you delete `.env` files by accident,
you can just copy corresponding values from the certificate.
If you delete the certificate `.yaml` file,
you can get a copy from the cluster.

# Deploy your certificate

This instruction assumes that you deploy the certificate
immediately after creating its `.yaml` file above.

If this is not the case then just substitute file names.

When deploying the staging certificate, [check related resources](#certificate-and-challenge-info).
DNS01 challenge can take several minutes, be patient.
HTTP01, on the other hand, is usually almost instant.
Staging certificates usually take quite a bit longer to produce than production ones.

```bash

# make sure that your certificate issuer is available in the desired namespace
cert_namespace=gateways

# first deploy a staging certificate to check that everything works as expected
kl -n $cert_namespace apply -f ./ingress/manual-certificates/env/$domain_name-cert-staging.yaml
# wait for the certificate to be approved
kl -n $cert_namespace get cert
# now that you know that challenge works
# deploy the production certificate without the fear of getting banned by letsencrypt limits
kl -n $cert_namespace apply -f ./ingress/manual-certificates/env/$domain_name-cert-production.yaml
kl -n $cert_namespace get cert

# if you want to use the certificate with gateway API from a different namespace
# modify secret name in the reference grant before applying
kl -n $cert_namespace apply -f ./ingress/manual-certificates/reference-grant.yaml

```

# Certificate and challenge info

Useful when checking that new issuer works,
or for debugging why certificate is not being approved.

```bash
# check that all three related resources are created
# certificaterequest: check the DENIED and READY values
# order: check STATE
kl -n $cert_namespace get cert
kl -n $cert_namespace get cr
kl -n $cert_namespace get order

# in case of errors, of if some resources are missing, check describes
kl -n $cert_namespace describe cert
kl -n $cert_namespace describe cr
kl -n $cert_namespace describe order

# in case certificaterequest and order aren't descriptive
kl -n cert-manager logs deployments/cert-manager | grep $domain_name

```

# Avoid re-creating production certificate when re-creating cluster

You can save the certificate and deploy it in the new cluster,
without requesting a new certificate from ACME provider.

```bash

# save
mkdir -p ./ingress/manual-certificates/env/
kl -n cm-manual get secrets main-wildcard -o yaml > ./ingress/manual-certificates/env/wildcard-secret.yaml

# restore
kl apply -f ./ingress/manual-certificates/env/wildcard-secret.yaml

```

# Using in ingress resources

Ingress resources need certificate in the same namespace.

Easy way to copy certificate to each required namespace is to use [replicator](../replicator/readme.md).

After deployment use `copy_label` from `domain.env`
as a label for namespace where you need to use the certificate.

You also need to adjust ingress spec:
- Remove issuer annotation.
- Set `spec.tls[].secretName` to match secret name from certificate spec.
