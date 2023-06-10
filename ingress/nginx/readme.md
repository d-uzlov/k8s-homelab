
kl apply -k ./ingress/nginx-1.6.4/

# Documentation

Annotations:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/annotations.md

Configmap:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/configmap.md

Beware of changes between versions.

# Generate deployment

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm search repo ingress-nginx --versions
helm template ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --version 4.7.0 \
  --namespace ingress-nginx \
  > ./ingress/nginx/nginx.yaml
```
