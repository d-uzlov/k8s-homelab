
# Setup for each domain which needs a certificate

References:
- https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/

Here we will create a separate issuer just for a single domain.
It's possible to use a single issuer for several domains,
but you need to run `/register` for each domain separately,
and put all of the credentials in a single file.
See cert-manager documentation for more info.

Also, sharing an issuer is less secure than using separate ones.

---

- Register in your `acme-dns` instance:

```bash

acmedns_mgmt="https://"$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
acmedns_mgmt="http://"$(kl -n cm-acme-dns get svc management -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
# acmedns_mgmt="https://"$(kl -n cm-acme-dns get ingress management -o go-template --template "{{ (index .spec.rules 0).host}}")

# Set to your actual domain
managed_domain=meoe.cloudns.be

# save output, we will need it for the cert-manager issuer
curl -X POST "$acmedns_mgmt/register" | jq . \
  > ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json

echo "This is your full domain: $(jq -r .fulldomain ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json)"

```

---

- Set CNAME record for `_acme-challenge.$managed_domain` that points to `acmedns-$managed_domain.json : fulldomain`

```bash

# check that CNAME reference is used
nslookup -type=CNAME _acme-challenge.$managed_domain 8.8.8.8
dig _acme-challenge.$managed_domain @8.8.8.8 TXT

```

---

- Set up cert-manager config:

```bash

# Create a config file for acme-dns client
jq -n \
  --slurpfile source ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json \
  '."'"$managed_domain"'" = $source[0]' \
  > ./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json

# set to your email
domain_admin_email=meoe@ya.ru
# example: domain_admin_email=user@example.org
secret_name=${domain_admin_email/@/-at-}
secret_name=${secret_name/_/-}

 cat << EOF > ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-staging.yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: $managed_domain-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $domain_admin_email
    privateKeySecretRef:
      name: letsencrypt-credentials-$secret_name
    solvers:
    - dns01:
        acmeDNS:
          host: http://management.cm-acme-dns.svc
          accountSecretRef:
            name: acme-dns-$managed_domain
            key: acmedns.json
EOF
sed ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-staging.yaml \
  -e 's/acme-staging-v02/acme-v02/g' \
  -e 's/-staging/-production/g' \
  > ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-production.yaml

# since we are using namespaced issuer, it will be available only in the selected namespace
issuer_namespace=gateways
kl -n $issuer_namespace create secret generic acme-dns-$managed_domain \
  --from-file acmedns.json=./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json \
  -o yaml --dry-run=client | kl apply -f -

kl -n $issuer_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-staging.yaml
kl -n $issuer_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-production.yaml

```

---

You can now use this issuer to create a certificate.

See here for an example how to create one:
[manual-certificates](../../manual-certificates/readme.md#create-certificate-from-template).
