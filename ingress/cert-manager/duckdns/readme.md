
# DuckDNS

This is a plugin for cert-manager that can add DNS-01 challenge support for DuckDNS.
The primary use of this is to get wildcard certificated from letsencrypt.

References:
- https://github.com/joshuakraitberg/cert-manager-webhook-duckdns

# Create config

Required for major config changes or updates.

You don't need to do it if you are just deploying it.

```bash
git clone https://github.com/joshuakraitberg/cert-manager-webhook-duckdns.git

# build deployment config
helm template duckdns-webhook \
  --values ./ingress/cert-manager/duckdns/helm-values.yaml \
  --namespace cm-duckdns \
  ./cert-manager-webhook-duckdns/charts/cert-manager-webhook-duckdns \
  | sed -e '/helm.sh\/chart/d' -e '/# Source:/d' \
  > ./ingress/cert-manager/duckdns/duckdns.gen.yaml
```

# Set up your local environment

```bash
mkdir -p ./ingress/cert-manager/duckdns/env
echo <<EOF > ./ingress/cert-manager/duckdns/env/duckdns.env
# Authentication token that allows you to set up DNS entries.
# You can find token on the DuckDNS website.
token=<token>
EOF
echo <<EOF > ./ingress/cert-manager/duckdns/env/letsencrypt.env
# Can be any valid email.
# Letsencrypt will send you a warning on this address
# a few days before any of your certificates expire.
email=example@example.com
EOF
```

# Deploy

```bash
kl create ns cm-duckdns
kl label ns cm-duckdns pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/cert-manager/duckdns/
kl -n cm-duckdns get pod -o wide
```

If you want to change namespace, change it in the helm template command.
Kustomize doesn't change namespace of ClusterRoleBinding and in cert-manager.io/inject-ca-from annotation.

After deployment you can go here to test certificate creation:
- [manual-certificates](../../manual-certificates/readme.md)

# Check duckdns TXT manually

You can use these commands to check that you are using the correct DuckDNS token,
and that the service is currently working as expected.

```bash
# don't forget to update these values before running the command
token="<token>"
domain="example"
# update TXT record
curl "https://www.duckdns.org/update?domains=$domain&token=$token&txt=test-2-txt-value"

# query TXT record
nslookup -q=txt example.duckdns.org
dig _acme-challenege.example.duckdns.org TXT
```
