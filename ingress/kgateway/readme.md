
# kgateway

References:
- https://kgateway.dev/docs/main/quickstart/

# Generate config

You only need to do this when updating the app.

```bash
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update ingress-nginx
# helm search repo ingress-nginx/ingress-nginx --versions --devel | head
helm show values oci://cr.kgateway.dev/kgateway-dev/charts/kgateway --version v2.1.0-main > ./ingress/kgateway/default-values.yaml
```

```bash

helm template kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds --version v2.1.0-main > ./ingress/kgateway/kgateway-crds.yaml

helm template kgateway --no-hooks \
  oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  --version v2.1.0-main \
  --namespace ingress-kgateway \
  --values ./ingress/kgateway/values.yaml \
  > ./ingress/kgateway/kgateway.gen.yaml

```

# deploy

```bash

kl apply -f ./ingress/kgateway/kgateway-crds.yaml --server-side

kl create ns ingress-kgateway
kl label ns ingress-kgateway pod-security.kubernetes.io/enforce=baseline
kl label ns ingress-kgateway ingress=ingress

kl apply -k ./ingress/kgateway/
kl -n ingress-kgateway get pod -o wide

# kgateway wants to create gatewayclass automatically
kl get gc

```

# Cleanup

```bash
kl delete -k ./ingress/kgateway/
kl delete ns ingress-kgateway
kl delete -f ./ingress/kgateway/kgateway-crds.yaml
```
