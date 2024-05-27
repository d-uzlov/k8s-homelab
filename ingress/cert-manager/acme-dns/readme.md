
# acme-dns

References:
- https://github.com/joohoi/acme-dns
- https://community.letsencrypt.org/t/help-me-understand-acme-dns/58892/2
- https://habr.com/ru/articles/674738/
- https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/

# Deploy

```bash
kl create ns cm-acme-dns
kl label ns cm-acme-dns pod-security.kubernetes.io/enforce=baseline

kl apply -f ./ingress/cert-manager/acme-dns/postgres.yaml
kl -n cm-acme-dns get pods -o wide -L spilo-role

kl apply -f ./ingress/cert-manager/acme-dns/service-dns.yaml
kl apply -f ./ingress/cert-manager/acme-dns/service-management.yaml
kl -n cm-acme-dns get svc

mkdir -p ./ingress/cert-manager/acme-dns/env/
cat << EOF > ./ingress/cert-manager/acme-dns/env/acme-dns.env
# acme-dns will serve on this domain
# all generated validation URLs will use this as a suffix,
# so set it to something public that will allow letsencrypt to connect to acme-dns via port 53
domain_suffix=acme.example.org
# there is no documentation what this does
# it should probably match Host of the NS record that's pointing to acme-dns?
ns_name=acme.example.org
# ns_value=acme-ns.example.org
# admin email address, where @ is substituted with .
admin_email=admin.example.org
EOF

kl apply -k ./ingress/cert-manager/acme-dns/
kl -n cm-acme-dns get pods -o wide

kl apply -k ./ingress/cert-manager/acme-dns/ingress-route/
kl -n cm-acme-dns get httproute

# test creating a domain for ACME
acmedns_mngt_domain=$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
curl -X POST "https://$acmedns_mngt_domain/register" | jq .
# manually substitute from /register output:
# X-Api-User from username
# X-Api-Key from password
# copy "subdomain" value from subdomain
curl -X POST \
  -H "X-Api-User: 1f426aab-94e1-4839-97eb-97f3263b1219" \
  -H "X-Api-Key: q3-ebN3B7N5BZZFfKvbZJoBdbRHdHXuoizd38I5X" \
  -d '{"subdomain": "aec39e42-3caa-4f69-9acd-59d843922634", "txt": "___validation_token_received_from_the_ca___"}' \
  "https://$acmedns_mngt_domain/update"
# check access locally
acmedns_lb=$(kl -n cm-acme-dns get svc dns -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
acme_challende_domain=aec39e42-3caa-4f69-9acd-59d843922634.acme.example.cloudns.be
nslookup -type=txt $acme_challende_domain $acmedns_lb
```

# Cleanup

```bash
kl delete -k ./ingress/cert-manager/acme-dns/ingress-route/
kl delete -k ./ingress/cert-manager/acme-dns/
kl delete -f ./ingress/cert-manager/acme-dns/service-dns.yaml
kl delete -f ./ingress/cert-manager/acme-dns/service-management.yaml
kl delete -f ./ingress/cert-manager/acme-dns/postgres.yaml
kl delete ns cm-acme-dns
```

# How it works

acme-dns uses [ACME challenge redirection](../acme.md#acme-delegation-for-dns01).

# External DNS setup

You need to have a domain and a DNS server with support for CNAME and NS records for this to work..

Configure DNS server serving `acme-dns.env:$domain_suffix` (`auth.example.org` in the example .env file):

- Set NS record for `$domain_suffix`.
  Like this: `auth.example.org. NS actual.address.of.server.`
- Make sure that domain that NS for `$domain_suffix` points to is resolvable.
  Like this: `actual.address.of.server. A 100.200.150.250` (set to actual public IP of your server)
- Make sure that your `acme-dns` server is available from the internet (configure firewall, NAT, etc.)

# Setup for each domain which needs a certificate

References:
- https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/

You can share some of this for different domains,
but it's better to do all of the setup for each domain separately,
unless you need a single certificate that's valid for several domains.

- Register at the `acme-dns`:

```bash
acmedns_mngt_domain=$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
# this is just for the file name for your convenience
managed_domain=test.example.com
# save output, we will nedd it for the cert-manager issuer
curl -X POST "https://$acmedns_mngt_domain/register" | jq . > ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json
```

- Set CNAME record for `_acme-challenge.your.domain` that points to `acmedns-$managed_domain.json : fulldomain`
- Create a config file for cert-manager:

```bash
jq -n --slurpfile source ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json '."'"$managed_domain"'" = $source[0]' > ./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json
```

- Create a secret:

```bash
cert_namespace=cm-manual
kl -n $cert_namespace create secret generic acme-dns-$managed_domain --from-file acmedns.json=./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json
```

- Create a corresponding issuer:

```bash
issuer_name=example
domain_admin_email=user@example.org
cat << EOF > ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer.yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: $issuer_name-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $domain_admin_email
    privateKeySecretRef:
      name: $issuer_name-staging
    solvers:
    - dns01:
        acmeDNS:
          host: https://$acmedns_mngt_domain
          accountSecretRef:
            name: acme-dns-$managed_domain
            key: acmedns.json
EOF
kl -n $cert_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer.yaml
```

- Create a corresponding certificate:

```bash
cert_name=example
cat << EOF > ./ingress/cert-manager/acme-dns/env/$managed_domain-cert.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $cert_name
spec:
  # shown in the cert info
  # overridden by dnsNames when checking signature
  commonName: $managed_domain
  dnsNames:
  - $managed_domain
  - '*.$managed_domain'
  secretName: $managed_domain-wildcard
  issuerRef:
    kind: Issuer
    name: $issuer_name-staging
  secretTemplate:
    annotations:
      replicator.v1.mittwald.de/replicate-to-matching: >
        $cert_name-copy
EOF
kl -n $cert_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-cert.yaml

kl -n cert-manager logs deployments/cert-manager | grep cloudns
```
