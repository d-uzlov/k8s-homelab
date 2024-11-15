
# Gateway API

By default k8s doesn't contain gateway API CRDs.
You need to install it manually to be able to use it.

References:
- https://gateway-api.sigs.k8s.io/guides/?h=crds#getting-started-with-gateway-api
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/

# Create CRDs

```bash
curl -L https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml \
  > ./ingress/gateway-api/install/experimental-install.yaml

kl apply -f ./ingress/gateway-api/install/experimental-install.yaml --server-side --force-conflicts
# patch adds "parent" column and short name `htr`
kl patch crd httproutes.gateway.networking.k8s.io --patch-file ./ingress/gateway-api/install/httproutes-print-patch.json --type json
```

References:
- https://github.com/kubernetes-sigs/gateway-api/releases

# Known implementations

References:
- https://gateway-api.sigs.k8s.io/implementations/

In this repo refer to the following:
- [cilium](../../network/cilium/readme.md)
- [envoy](../envoy/readme.md)
- [istio](../istio/readme.md)

# Deploy gateway

Deploy appropriate certificate before creating gateways: [manual-certificates](../manual-certificates/readme.md).

You can create many gateways but ingress routes in this repo are configured to use these two.

```bash
mkdir -p ./ingress/gateway-api/public/env/
cat <<EOF > ./ingress/gateway-api/public/env/gateway-class.env
# set to your preferred gateway class
gateway_class=cilium
EOF
mkdir -p ./ingress/gateway-api/private/env/
cat <<EOF > ./ingress/gateway-api/private/env/gateway-class.env
# set to your preferred gateway class
gateway_class=cilium
EOF

kl create ns gateways
kl label ns gateways ingress=ingress

kl apply -k ./ingress/gateway-api/private/
kl -n gateways describe gateway main-private
kl -n gateways describe httproute http-redirect-private

kl apply -k ./ingress/gateway-api/public/
kl -n gateways describe gateway main-public
kl -n gateways describe httproute http-redirect-public

kl -n gateways get gateway
```

References:
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/

# Cleanup

```bash
kl delete -k ./ingress/gateway-api/private/
kl delete -k ./ingress/gateway-api/public/
kl delete ns gateways
```
