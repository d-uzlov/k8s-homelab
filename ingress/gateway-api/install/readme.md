
# Gateway API

By default k8s doesn't contain gateway API CRDs.
You need to install it manually to be able to use it.

References:
- https://gateway-api.sigs.k8s.io/guides/?h=crds#getting-started-with-gateway-api
- https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
- https://github.com/kubernetes-sigs/gateway-api

# Create CRDs

```bash

curl -L https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml > ./ingress/gateway-api/install/experimental-install.yaml

kl apply -k ./ingress/gateway-api/install/ --server-side --force-conflicts

```

There is a patch that allows you to use `htr` short name for http routes,
and enhances httproute view in kubectl.
However, httproute status is not well defined,
so kubectl view can be misleading in case more that one gateway ever touched httproute.
