
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
- Acme-DNS domain should support NS records

Also, each domain that you want to request certificates for should support CNAME records.

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
# should match the value of NS record for domain_suffix from the parent DNS server
ns_name=ns1.acme.example.org
# admin email address, where @ is substituted with .
admin_email=admin.example.org
EOF

mkdir -p ./ingress/cert-manager/acme-dns/postgres-cnpg/env/
 cat << EOF > ./ingress/cert-manager/acme-dns/postgres-cnpg/env/postgres-sc.env
postgres_storage_class=nvmeof
EOF

# make sure that bucket_path is empty
# otherwise cnpg will refuse to upload backups
# apparently it shouldn't even start, but currently there is only error in logs:
#     WAL archive check failed for server postgres: Expected empty archive
 cat << EOF >  ./ingress/cert-manager/acme-dns/postgres-cnpg/env/backup-s3.env
server_address=http://nas.example.com:9000/
bucket_path=s3://postgres-test/cm-acme-dns/
EOF

 cat << EOF >  ./ingress/cert-manager/acme-dns/postgres-cnpg/env/backup-s3-credentials.env
key=dmzER5pleUdusVaG9n8d
secret=zD07Jfk483DAJU8soRLZ4x9xdbtsU1QPcnU2eCp7
EOF

```

References:
- Explanation of how domains interact with each other in settings
- - https://github.com/joohoi/acme-dns/issues/238#issuecomment-1047244425

# Deploy

```bash

kl create ns cm-acme-dns
kl label ns cm-acme-dns pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/cert-manager/acme-dns/postgres-cnpg/
kl -n cm-acme-dns get cluster
kl -n cm-acme-dns describe cluster postgres
kl -n cm-acme-dns get pvc
kl -n cm-acme-dns get pods -o wide -L role -L cnpg.io/jobRole
kl -n cm-acme-dns get svc
kl -n cm-acme-dns get secrets
kl cnpg -n cm-acme-dns status postgres

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
kl delete -k ./ingress/cert-manager/acme-dns/postgres-cnpg/
kl delete ns cm-acme-dns
```

# Check local server config

This just checks that acme-dns is working in a vacuum.
This can be useful to check database connectivity and stuff.

```bash

# test creating a domain for ACME
acmedns_mgmt="https://"$(kl -n cm-acme-dns get httproute management -o go-template --template "{{ (index .spec.hostnames 0)}}")
acmedns_mgmt="http://"$(kl -n cm-acme-dns get svc management -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
# acmedns_mgmt="https://"$(kl -n cm-acme-dns get ingress management -o go-template --template "{{ (index .spec.rules 0).host}}")
registration=$(curl -X POST "$acmedns_mgmt/register")
echo $registration | jq .
curl -X POST \
  -H "X-Api-User: $(echo $registration | jq .username -r)" \
  -H "X-Api-Key: $(echo $registration | jq .password -r)" \
  -d '{"subdomain": '"$(echo $registration | jq .subdomain)"', "txt": "___validation_token_received_from_the_ca___"}' \
  "$acmedns_mgmt/update"

# check access locally
acmedns_lb=$(kl -n cm-acme-dns get svc dns -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
nslookup -type=txt $(echo $registration | jq .fulldomain -r) $acmedns_lb
dig $(echo $registration | jq .fulldomain -r) @$acmedns_lb TXT

# after you have external access set up, check via google
nslookup -type=txt $(echo $registration | jq .fulldomain -r) 8.8.8.8
dig $(echo $registration | jq .fulldomain -r) @8.8.8.8 TXT

```

# External DNS setup

Before using your own acme-dns instance, you need to set up remote access to it.

This is just a standard setup for a new DNS server, it's not specific for acme-dns.

`domain_suffix` must match the value from `./ingress/cert-manager/acme-dns/env/acme-dns.env`.

- Create `A` or `AAAA` record `$actual_acmedns_server_domain` that points to your acme-dns external address
- - `$actual_acmedns_server_domain. A $actual_acmedns_server_ip`
- - For example: `acme-ns.example.org. A 100.200.150.250`
- Point NS record in the parent `$domain_suffix` to `$actual_acmedns_server_domain`:
- - `$domain_suffix. NS $actual_acmedns_server_domain.`
- - For example: `acme.example.org. NS acme-ns.example.org.`
- Make sure that port 53 at `$actual_acmedns_server_ip` is available from the internet
- - Configure firewall, NAT, etc.
- - UDP port access must be configured
- - TCP is optional but may theoretically be required in some scenarios

In case you have a single public IP, if you already host
a public DNS server and don't want to replace it with acme-dns,
you can probably setup DNS forwarding,
but this is out of scope of this documentation.

# Domain setup

[Domain setup](./domain-setup.md)
