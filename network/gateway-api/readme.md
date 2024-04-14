
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
