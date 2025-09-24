
# gateway API

By default k8s doesn't contain gateway API CRDs.
You need to install it manually to be able to use it.

References:
- https://gateway-api.sigs.k8s.io/guides/?h=crds#getting-started-with-gateway-api
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
- https://github.com/kubernetes-sigs/gateway-api

# known implementations

References:
- https://gateway-api.sigs.k8s.io/implementations/

In this repo refer to the following:
- [cilium](../../network/cilium/readme.md)
- [envoy](../envoy/readme.md)
- [istio](../istio/readme.md)

# deploy

Deploy CRDs first: [install CRDs readme](./install/readme.md)

Deploy appropriate certificate before creating gateways: [manual-certificates](../manual-certificates/readme.md).

```bash

kl create ns gateways
kl label ns gateways pod-security.kubernetes.io/enforce=baseline
# attempt to setup network policies
kl label ns gateways ingress=ingress

kl -n gateways get gateway

```

You can create many gateways but ingress routes in this repo are configured to use these two:
- [](./private/readme.md)
