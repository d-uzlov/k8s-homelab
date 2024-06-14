
# Envoy

References:
- https://github.com/envoyproxy/gateway
- https://gateway.envoyproxy.io/v1.0.1/install/install-helm/

# Generate config

You only need to do this when updating the app.

```bash
git ls-remote https://github.com/envoyproxy/gateway.git | grep tags | tail
git clone --depth 1 --branch v1.0.1 https://github.com/envoyproxy/gateway.git ./ingress/envoy/envoyproxy-gateway/

rm -r ./ingress/envoy/crds/
cp -r ./ingress/envoy/envoyproxy-gateway/charts/gateway-helm/crds/generated/ ./ingress/envoy/crds/

ImageRepository=docker.io/envoyproxy/gateway ImageTag=v1.0.1 envsubst \
  < ./ingress/envoy/envoyproxy-gateway/charts/gateway-helm/values.tmpl.yaml \
  > ./ingress/envoy/envoyproxy-gateway/charts/gateway-helm/values.yaml
helm show values ./ingress/envoy/envoyproxy-gateway/charts/gateway-helm/ > ./ingress/envoy/default-values.yaml
```

```bash
helm template \
  envoy-gateway \
  ./ingress/envoy/envoyproxy-gateway/charts/gateway-helm/ \
  --namespace envoy-gateway \
  --values ./ingress/envoy/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e '/creationTimestamp: null/d' \
  > ./ingress/envoy/envoy.gen.yaml
```

# Deploy

```bash
kl apply -f ./ingress/envoy/crds/

kl create ns envoy-gateway
kl label ns envoy-gateway pod-security.kubernetes.io/enforce=baseline

kl apply -f ./ingress/envoy/envoy.gen.yaml
kl -n envoy-gateway get pod -o wide

kl apply -f ./ingress/envoy/gateway-class.yaml
```

Don't forget to enable NAT port forwarding if needed.

# Cleanup

```bash
kl delete -f ./ingress/envoy/gateway-class.yaml
kl delete -f ./ingress/envoy/envoy.gen.yaml
kl delete ns envoy-gateway

kl delete -f ./ingress/envoy/crds/
```

# Create gateway

Create [main gateway](../gateway-api/readme.md) for the cluster.

# Test

References:
- [ingress example](../../test/ingress/readme.md)
