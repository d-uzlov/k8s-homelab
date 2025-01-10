
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
helm show values istio/base --version 1.24.0 > ./ingress/istio/base/default-values.yaml
helm template \
  --include-crds \
  istio-base \
  istio/base \
  --version 1.24.0 \
  --namespace istio \
  --values ./ingress/istio/base/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e '\|app.kubernetes.io/name|d' -e '\|Created if this is not a remote istiod, OR if it is and is also a config cluster|d' \
  > ./ingress/istio/base/istio-base.gen.yaml

helm show values istio/istiod --version 1.24.0 > ./ingress/istio/istiod/default-values.yaml
helm template \
  --include-crds \
  istio-istiod \
  istio/istiod \
  --version 1.24.0 \
  --namespace istio \
  --values ./ingress/istio/istiod/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e '\|app.kubernetes.io/name|d' -e '\|Created if this is not a remote istiod, OR if it is and is also a config cluster|d' \
  > ./ingress/istio/istiod/istio-istiod.gen.yaml

sed -n '/mesh:/,/---/{//!p}' ./ingress/istio/istiod/istio-istiod.gen.yaml | sed 's/^    //' \
  > ./ingress/istio/mesh-config/default-mesh-config.yaml

```

# Deploy

```bash

kl create ns istio
kl label ns istio pod-security.kubernetes.io/enforce=baseline

kl apply -f ./ingress/istio/base/istio-base.gen.yaml --server-side --force-conflicts

# generate mesh config
# check out if this issue is fixed, maybe we can stop doing this shit just to enable some extensions:
# - https://github.com/istio/istio/issues/35165
mkdir -p ./ingress/istio/mesh-config/env/
cat << EOF > ./ingress/istio/mesh-config/env/mesh-config.yaml
$(cat ./ingress/istio/mesh-config/default-mesh-config.yaml)
extensionProviders:
$(cat ./ingress/istio/mesh-config/env/extension-*.yaml)
EOF

mkdir -p ./ingress/istio/istiod/env/ &&
kl kustomize ./ingress/istio/mesh-config/ > ./ingress/istio/istiod/env/mesh-config.yaml &&
kl apply -k ./ingress/istio/istiod/

kl -n istio get pod -o wide
# check if istio created its gateway class
kl get gc

```

If you want to use istio as gateway controller,
you should create a gateway with class `istio`:
[gateway API setup](../gateway-api/readme.md).

# Cleanup

```bash
kl delete -f ./ingress/istio/istiod/istio-istiod.gen.yaml
kl delete -f ./ingress/istio/base/istio-base.gen.yaml
kl delete ns istio
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
