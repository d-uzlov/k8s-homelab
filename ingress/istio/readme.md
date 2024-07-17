
# Istio

Istio is generally a service mesh,
but this repo only uses it for ingress via Gateway API.

References:
- https://github.com/istio/istio/releases

# Generate config

You only need to do this when updating the app.

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
helm search repo istio/base --versions --devel | head
```

```bash
helm show values istio/base --version 1.22.3 > ./ingress/istio/base/default-values.yaml
helm template \
  --include-crds \
  istio-base \
  istio/base \
  --version 1.22.3 \
  --namespace istio \
  --values ./ingress/istio/base/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/istio/base/istio-base.gen.yaml

helm show values istio/istiod --version 1.22.3 > ./ingress/istio/istiod/default-values.yaml
helm template \
  --include-crds \
  istio-istiod \
  istio/istiod \
  --version 1.22.3 \
  --namespace istio \
  --values ./ingress/istio/istiod/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/istio/istiod/istio-istiod.gen.yaml
```

# Deploy

```bash
kl create ns istio
kl label ns istio pod-security.kubernetes.io/enforce=baseline

kl apply -f ./ingress/istio/base/istio-base.gen.yaml --server-side --force-conflicts
kl apply -f ./ingress/istio/istiod/istio-istiod.gen.yaml
kl -n istio get pod -o wide

# get load balancer external ip for DNS or NAT port forwarding
kl -n istio get svc nginx-controller
```

# Cleanup

```bash
kl delete -k ./ingress/istio/
kl delete ns istio
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
