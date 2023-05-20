
https://github.com/joshuakraitberg/cert-manager-webhook-duckdns

Clone the repo and build deployment config:
```bash
helm template cert-manager-webhook-duckdns \
  --values ./ingress/cert-manager/duckdns/helm-values.yaml \
  --namespace cm-duckdns \
  ./cert-manager-webhook-duckdns/charts/cert-manager-webhook-duckdns \
  > ./ingress/cert-manager/duckdns/duckdns.yaml

echo <<EOF > ./ingress/cert-manager/duckdns/secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: duckdns-token
  namespace: cm-duckdns
type: Opaque
stringData:
  token: <token>
EOF

kl apply -k ./ingress/cert-manager/duckdns/
kl apply -f ./ingress/cert-manager/duckdns/issuers.yaml

kl apply -f ./ingress/cert-manager/duckdns/certificate.yaml
```

If you want to change namespace, change it in the helm template command.
Kustomize doesn't change namespace of ClusterRoleBinding and in cert-manager.io/inject-ca-from annotation.
Don't forget to change namespace in `duckdns-token` secret.

# Check duckdns TXT manually

Don't forget to update token in the url in the command below.

```bash
curl 'https://www.duckdns.org/update?domains=example&token=<token>&txt=test-2-txt-value'

nslookup -q=txt example.duckdns.org
dig _acme-challenege.example.duckdns.org TXT
```
