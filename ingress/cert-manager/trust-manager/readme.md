
# trust-manager

References:
- https://github.com/cert-manager/trust-manager

# generate config

You only need to do this when updating the app.

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm search repo jetstack/trust-manager --versions --devel | head
helm show values jetstack/trust-manager --version v0.19.0 > ./ingress/cert-manager/trust-manager/default-values.yaml
```

```bash

mkdir -p ./ingress/cert-manager/trust-manager/env/

helm template \
  trust-manager jetstack/trust-manager \
  --values ./ingress/cert-manager/trust-manager/values.yaml \
  --version v0.19.0 \
  --namespace cert-manager \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/cert-manager/trust-manager/env/trust-manager-raw.gen.yaml

yq 'select(.kind == "CustomResourceDefinition")' ./ingress/cert-manager/trust-manager/env/trust-manager-raw.gen.yaml > ./ingress/cert-manager/trust-manager/trust-manager-crd.gen.yaml
yq 'select(.kind != "CustomResourceDefinition")' ./ingress/cert-manager/trust-manager/env/trust-manager-raw.gen.yaml > ./ingress/cert-manager/trust-manager/trust-manager.gen.yaml

```

# deploy

```bash

kl apply -f ingress/cert-manager/trust-manager/trust-manager-crd.gen.yaml --server-side

kl create ns cert-manager
kl label ns cert-manager pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/cert-manager/trust-manager/
kl -n cert-manager get pod -o wide

kl -n cert-manager get cert
kl -n cert-manager get issuer
kl get clusterissuer cluster-ca

```

# cleanup

```bash

kl delete -k ./ingress/cert-manager/
kl delete ns cert-manager
kl delete -f ingress/cert-manager/trust-manager/trust-manager-crd.gen.yaml

```

# deploy bundle

```bash

# initially copy from template
# but later you might want to modify it manually
cp ./ingress/cert-manager/trust-manager/bundle.template.yaml ./ingress/cert-manager/trust-manager/env/bundle.yaml

kl apply -f ./ingress/cert-manager/trust-manager/env/bundle.yaml
kl get bundle
kl describe bundle ca.trust-manager.default

kl describe secrets ca.trust-manager.default

```
