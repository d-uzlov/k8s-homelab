
# k8s network policies

References:
- https://kubernetes.io/docs/concepts/services-networking/network-policies/
- https://www.redhat.com/en/blog/guide-to-kubernetes-ingress-network-policies
- https://github.com/ahmetb/kubernetes-network-policy-recipes

# Apply

```bash

# don't forget to add `-n <namespace>`
kl apply -f ./network/network-policies/deny-ingress.yaml
kl apply -f ./network/network-policies/deny-egress.yaml
kl apply -f ./network/network-policies/allow-same-namespace.yaml
kl apply -f ./network/network-policies/allow-lan.yaml

```
