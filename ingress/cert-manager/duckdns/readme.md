
https://github.com/joshuakraitberg/cert-manager-webhook-duckdns

# DuckDNS

This is aplugin for cert-manager that can add DNS-01 challenge support for DuckDNS.
The primary use of this is to get wildcard certificated from letsencrypt.

# Deploy

```bash
git clone https://github.com/joshuakraitberg/cert-manager-webhook-duckdns.git

# build deployment config
helm template cert-manager-webhook-duckdns \
  --values ./ingress/cert-manager/duckdns/helm-values.yaml \
  --namespace cm-duckdns \
  ./cert-manager-webhook-duckdns/charts/cert-manager-webhook-duckdns \
  > ./ingress/cert-manager/duckdns/duckdns.yaml

# Init once
mkdir -p ./ingress/cert-manager/duckdns/secret/env
echo <<EOF > ./ingress/cert-manager/duckdns/secret/env/duckdns.env
# copy token from duckdns website
token=<token>
EOF
# Init once
echo <<EOF > ./ingress/cert-manager/duckdns/secret/env/letsencrypt.env
# Can be any valid email.
# You will get a warning email from letsencrypt
# if you forget to update you certificate.
email=example@example.com
EOF

kl create ns cm-duckdns

kl apply -k ./ingress/cert-manager/duckdns/

kl apply -f ./ingress/cert-manager/duckdns/certificate.yaml
```

If you want to change namespace, change it in the helm template command.
Kustomize doesn't change namespace of ClusterRoleBinding and in cert-manager.io/inject-ca-from annotation.

# Check duckdns TXT manually

Don't forget to update token in the url in the command below.

```bash
# update TXT record
curl 'https://www.duckdns.org/update?domains=example&token=<token>&txt=test-2-txt-value'

# query TXT record
nslookup -q=txt example.duckdns.org
dig _acme-challenege.example.duckdns.org TXT
```
