
# acme-dns

References:
- https://github.com/joohoi/acme-dns
- https://community.letsencrypt.org/t/help-me-understand-acme-dns/58892/2
- https://habr.com/ru/articles/674738/
- https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/

acme-dns allow you to move ACME validation to a separate server.

This has 2 main advantages:
- You don't need a specialized plugin or webhook for the cert-manager, you can use it with any DNS server
- Security is improved, because you don't need to provide full access to your main DNS server to the cluster

You don't need to deploy your own instance of acme-dns to use it.
You can use absolutely any instance for any domain,
you just need to configure your main DNS server properly.

However, remember, that by using an acme-dns instance for ACME validation,
you grant it the ability to issue a certificate based on DNS01 challenge at any time.
Malicious server could leverage it to impersonate your server.

Requirements:
- Static public IP
- Access to port 53 on that IP
- Main domain should support CNAME records
- You should also have a domain that supports NS records.
For a homelab it would probably be more convenient
to use a subdomain of your main domain
but you can absolutely host your acme-dns on a different domain if you want to.

# How it works

acme-dns uses [ACME challenge redirection](../acme.md#acme-delegation-for-dns01).

# Init server environment

```bash
mkdir -p ./ingress/cert-manager/acme-dns/env/
cat << EOF > ./ingress/cert-manager/acme-dns/env/acme-dns.env
# acme-dns will serve on this domain
# all generated validation URLs will use this as a suffix,
# so set it to something public that will allow letsencrypt to connect to acme-dns via port 53
domain_suffix=acme.example.org
# there is no documentation of what this does
# it should probably match Host value of the NS record that's pointing to acme-dns?
ns_name=acme.example.org
# admin email address, where @ is substituted with .
admin_email=admin.example.org
EOF
```

# Deploy

```bash
kl create ns cm-acme-dns
kl label ns cm-acme-dns pod-security.kubernetes.io/enforce=baseline

kl apply -f ./ingress/cert-manager/acme-dns/postgres.yaml
kl -n cm-acme-dns get pods -o wide -L spilo-role

kl apply -f ./ingress/cert-manager/acme-dns/service-dns.yaml
kl apply -f ./ingress/cert-manager/acme-dns/service-management.yaml
kl -n cm-acme-dns get svc

kl apply -k ./ingress/cert-manager/acme-dns/
kl -n cm-acme-dns get pods -o wide

kl apply -k ./ingress/cert-manager/acme-dns/ingress-route/
kl -n cm-acme-dns get httproute
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

# Check local server config

This just checks that acme-dns is working in a vacuum.
This can be useful to check database connectivity and stuff.

```bash
# test creating a domain for ACME
acmedns_mngt_domain=$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
registration=$(curl -X POST "https://$acmedns_mngt_domain/register")
echo $registration | jq .
curl -X POST \
  -H "X-Api-User: $(echo $registration | jq .username -r)" \
  -H "X-Api-Key: $(echo $registration | jq .password -r)" \
  -d '{"subdomain": '"$(echo $registration | jq .subdomain)"', "txt": "___validation_token_received_from_the_ca___"}' \
  "https://$acmedns_mngt_domain/update"
# check access locally
acmedns_lb=$(kl -n cm-acme-dns get svc dns -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
nslookup -type=txt $(echo $registration | jq .fulldomain -r) $acmedns_lb
```

# External DNS setup

Before using your own acme-dns instance, you need to set up remote access to it.

This is just a standard setup for a new DNS server, it's not specific for acme-dns.

`domain_suffix` must match the value from `./ingress/cert-manager/acme-dns/env/acme-dns.env`.

- Set NS record in the parent domain of `$domain_suffix`: 
- - `$domain_suffix. NS $actual_acmedns_server_domain.`
- - For example: `acme.example.org. NS acme-ns.example.org.`
- Make sure that A record for `$actual_acmedns_server_domain` can be resolved to real server IP
- - `$actual_acmedns_server_domain. A $actual_acmedns_server_ip`
- - For example: `acme-ns.example.org. A 100.200.150.250`
- Make sure that port 53 at `$actual_acmedns_server_ip` is available from the internet
- - Configure firewall, NAT, etc.
- - UDP port access must be configured
- - TCP is optional but may theoretically be required in some scenarios

In case you have a single public IP, if you already have
a public DNS server and don't want to replace it with acme-dns,
you can probably setup DNS forwarding,
but this is out of scope of this documentation.

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

- Register at the `acme-dns`:

```bash
acmedns_mngt_domain=$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
# Set to your actual domain
managed_domain=test.example.com
# save output, we will nedd it for the cert-manager issuer
curl -X POST "https://$acmedns_mngt_domain/register" | jq . > ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json

echo "This if your full domain: $(jq -r .fulldomain ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json)"
```

---

- Set CNAME record for `_acme-challenge.$managed_domain` that points to `acmedns-$managed_domain.json : fulldomain`

```bash
# check that CNAME reference is used
nslookup -type=txt _acme-challenge.$managed_domain
```

---

- Set up cert-manager config:

```bash
# Create a config file for acme-dns client
jq -n --slurpfile source ./ingress/cert-manager/acme-dns/env/$managed_domain-domain-info.json '."'"$managed_domain"'" = $source[0]' > ./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json

domain_admin_email=user@example.org
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
      name: letsencrypt-creds-${domain_admin_email/@/-at-}
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

# since we are using namespaced issuer, it will only be available in thie selected namespace
issuer_namespace=gateways
kl -n $issuer_namespace create secret generic acme-dns-$managed_domain --from-file acmedns.json=./ingress/cert-manager/acme-dns/env/$managed_domain-acmedns.json
kl -n $issuer_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-staging.yaml
kl -n $issuer_namespace apply -f ./ingress/cert-manager/acme-dns/env/$managed_domain-issuer-production.yaml
```

---

You can now use this issuer to create a certificate.

See here for an example how to create one: [manual-certificates](../../manual-certificates/readme.md#create-certificate-from-template).
