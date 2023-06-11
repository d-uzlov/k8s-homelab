
# Documentation

Annotations:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/annotations.md

Configmap:
https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/docs/user-guide/nginx-configuration/configmap.md

Beware of changes between versions.

# Generate deployment

You can change settings if you want:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm search repo ingress-nginx --versions
helm template ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.7.0 \
  --namespace ingress-nginx \
  --set nameOverride=nginx \
  --set fullnameOverride=nginx \
  --set controller.terminationGracePeriodSeconds=30 \
  --set controller.kind=DaemonSet \
  > ./ingress/nginx/nginx.yaml

# if you want to learn about more about available options
helm show values ingress-nginx/ingress-nginx --version 4.7.0 > ./ingress/nginx/default-values.yaml
```

# Deploy

```bash
kl create ns ingress-nginx
kl apply -k ./ingress/nginx
```
