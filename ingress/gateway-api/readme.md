
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
- [istio](../istio/readme.md) (recommended)
- [cilium](../../network/cilium/readme.md)
- [envoy](../envoy/readme.md)

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

You can create many gateways but ingress routes in this repo are configured to use these three:
- [private](./private/readme.md)
- [public](./public/readme.md)
- [protected](./protected/readme.md)

# gateway api implementation comparison

References:
- https://github.com/howardjohn/gateway-api-bench
- https://www.reddit.com/r/kubernetes/comments/1l7dna0/evaluating_realworld_performance_of_gateway_api/

tldr:
- istio, kgateway — good
- cilium, envoy, kong, traefik, nginx — bad

APISIX, haproxy, contour weren't tested (yet).

Out of 2 verified good gateways istio has relatively good and flexible configuration,
while kgateway doesn't even support external auth.
