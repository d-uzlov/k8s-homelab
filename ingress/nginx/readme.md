
# Documentation

Annotations:
- https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/annotations.md

Configmap:
- https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/configmap.md

Beware of changes between versions.

References:
- https://github.com/kubernetes/ingress-nginx

Prerequisites:
- TLS certificate (preferably public one)
- - For example: [wildcard certificate](../manual-certificates/readme.md)
- [optional] [DNS for exposed services](../dns-k8s-gateway/readme.md)

# Generate config

You only need to do this when updating the app.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx
helm search repo ingress-nginx/ingress-nginx --versions --devel | head
helm show values ingress-nginx/ingress-nginx > ./ingress/nginx/default-values.yaml
```

```bash
helm template \
  ingress-nginx \
  ingress-nginx/ingress-nginx \
  --version 4.10.0 \
  --namespace ingress-nginx \
  --values ./ingress/nginx/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/nginx/nginx.gen.yaml
```

# Deploy

```bash
kl create ns ingress-nginx
kl label ns ingress-nginx pod-security.kubernetes.io/enforce=baseline
kl label ns ingress-nginx ingress=ingress

kl apply -k ./ingress/nginx/
kl -n ingress-nginx get pod -o wide

# get load balancer external ip for DNS or NAT port forwarding
kl -n ingress-nginx get svc nginx-controller
```

Don't forget to enable NAT port forwarding if needed.

# Cleanup

```bash
kl delete -k ./ingress/nginx/
kl delete ns ingress-nginx
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
