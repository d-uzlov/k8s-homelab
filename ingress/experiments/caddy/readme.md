https://github.com/caddyserver/ingress

# Deploy caddy (вместо nginx+cert-manager)

```bash
kl create namespace caddy-system
helm install \
  --kubeconfig /mnt/a/var/ubuntu-k8s/kubeadm-master-config.yaml \
  --namespace=caddy-system \
  --repo https://caddyserver.github.io/ingress/ \
  --atomic \
  mycaddy \
  caddy-ingress-controller
```

kl apply -f ./ingress/caddy/global-configmap.yaml
kl apply -f ./ingress/caddy/sample.yaml
kl apply -f ./ingress/caddy/torrent-ingress.yaml
