
# Documentation

Annotations:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/annotations.md

Configmap:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/configmap.md

Beware of changes between versions.

# Generate deployment

Required for major config changes or updates.

You don't need to do it if you are just deploying it.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm search repo ingress-nginx --versions | head
helm template ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.7.1 \
  --namespace ingress-nginx \
  --values ./ingress/nginx/values.yaml \
  | sed -e '/helm.sh\/chart/d' -e '/# Source:/d' \
  > ./ingress/nginx/nginx.gen.yaml

# if you want to learn about more about available options
helm show values ingress-nginx/ingress-nginx --version 4.7.1 > ./ingress/nginx/default-values.yaml
```

# Deploy

```bash
kl create ns ingress-nginx
kl apply -k ./ingress/nginx

kl apply -f ./ingress/nginx/service.yaml
kl -n ingress-nginx get svc nginx
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
