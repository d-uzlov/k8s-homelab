
https://doc.traefik.io/traefik/getting-started/quick-start-with-kubernetes/

helm repo add traefik https://traefik.github.io/charts

```bash
helm template \
    --values ./ingress/traefik/values.yaml \
    --namespace ingress-traefik \
    --version v22.1.0 \
    ingress-traefik traefik/traefik \
    > ./ingress/traefik/deployment.yaml
```

```bash
kl create ns ingress-traefik
kl apply -f ./ingress/traefik/deployment.yaml 
```