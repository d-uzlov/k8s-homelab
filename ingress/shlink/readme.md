
# shlink

Link shortener.

References:
- https://shlink.io/documentation/install-docker-image/
- https://shlink.io/documentation/install-docker-image/

# Setup ingress

- Wildcard ingress on the main domain

This setup uses the main domain directly, without a subdomain,
unlike other ingress configs in the repo.

```bash
kl label ns --overwrite shlink copy-wild-cert=main
kl apply -k ./ingress/shlink/ingress-wildcard/
kl -n shlink get ingress
```

# Deploy

```bash
kl create ns shlink

kl -n shlink get ingress
shlink_public_domain=$(kl -n shlink get ingress shlink -o go-template --template "{{range .spec.rules}}{{.host}}{{end}}")
kl -n shlink create configmap public-domain --from-literal public_domain="$shlink_public_domain" -o yaml --dry-run=client | kl apply -f -

kl apply -k ./ingress/shlink/
kl -n shlink get pod -o wide
```

# Cleanup

```bash
kl delete -k ./ingress/shlink/
kl delete ns shlink
```

# CLI

```bash
# list available commands
kl -n shlink exec deployments/shlink -- shlink
# generate link with random value
kl -n shlink exec deployments/shlink -- shlink short-url:create -- https://example.com/
# generate link with predefined value
kl -n shlink exec deployments/shlink -- shlink short-url:create --custom-slug qwe -- https://example.com/qwe
# remove previously generated link (useful for predefined links)
kl -n shlink exec deployments/shlink -- shlink short-url:delete -- qwe

# you can also add --domain <value> to any command to use a custom domain
```
