
# Contour

References:
- https://projectcontour.io/getting-started/

# Generate config

You only need to do this when updating the app.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
helm search repo bitnami/contour --versions --devel | head
helm show values bitnami/contour --version 18.2.9 > ./ingress/contour/default-values.yaml
```

```bash
helm template \
  contour \
  bitnami/contour \
  --version 18.2.9 \
  --namespace contour \
  --values ./ingress/contour/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/contour/contour.gen.yaml

# v1.29.1 corresponds to chart version 18.2.9
curl -fsSL https://github.com/projectcontour/contour/raw/v1.29.1/examples/contour/01-crds.yaml \
  > ./ingress/contour/crds.yaml

curl -fsSL https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml \
  > ./ingress/contour/provisioner.yaml
```

# Deploy

```bash
kl create ns contour
kl label ns contour pod-security.kubernetes.io/enforce=baseline

# kl apply -f ./ingress/contour/crds.yaml --server-side
# kl apply -f ./ingress/contour/contour.gen.yaml
kl apply -f ./ingress/contour/provisioner.yaml
kl -n contour get pod -o wide

# get load balancer external ip for DNS or NAT port forwarding
kl -n contour get svc nginx-controller
```

# Cleanup

```bash
kl delete -k ./ingress/istio/
kl delete ns istio
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
