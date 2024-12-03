
https://appscode.com/products/kubed/v0.12.0/setup/install/

# Install

```bash
helm repo add appscode https://charts.appscode.com/stable/
helm repo update

helm template kubed appscode/kubed \
  --version v0.13.2 \
  --namespace kubed \
  --no-hooks \
  > ./ingress/kubed/kubed.yaml

kl apply -f ./ingress/kubed/kubed.yaml
```
