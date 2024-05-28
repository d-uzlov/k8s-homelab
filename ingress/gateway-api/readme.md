
# Gateway API

By default k8s doesn't contain gateway API CRDs.

This readme has instructions to fix it.

References:
- https://gateway-api.sigs.k8s.io/guides/?h=crds#getting-started-with-gateway-api
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/

# Deploy

```bash
# wget https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
kl apply -f ./network/gateway-api/experimental-install.yaml --server-side
```

# Deploy gateway

Deploy appropriate certificate before creating gateways: [manual-wildcard](../manual-wildcard/readme.md).

```bash
mkdir -p ./ingress/gateway-api/gateway/env/
cat <<EOF > ./ingress/gateway-api/gateway/env/gateway-class.env
# set to your preferred gateway class
gateway_class=cilium
EOF

kl create ns gateways

kl apply -k ./network/cilium/gateway/
kl -n gateways describe gateway main-private
kl -n gateways describe gateway main-public

kl -n gateways describe httproute http-redirect-public
kl -n gateways describe httproute http-redirect-private

kl -n gateways get gateway
```

References:
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
