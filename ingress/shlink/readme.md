
# shlink

Link shortener.

References:
- https://shlink.io/documentation/install-docker-image/
- https://shlink.io/documentation/install-docker-image/

# Prerequisites

- [Postgres Operator](../../storage/postgres/readme.md)

# Deploy

After you create the namespace, [#setup the ingress](#setup-ingress).

```bash
kl create ns shlink

# setup ingress before this
kl -n shlink get ingress
shlink_public_domain=$(kl -n shlink get ingress shlink -o go-template --template "{{range .spec.rules}}{{.host}}{{end}}")
kl -n shlink create configmap public-domain --from-literal public_domain="$shlink_public_domain" -o yaml --dry-run=client | kl apply -f -

# note: this uses `block` storage class
kl apply -f ./ingress/shlink/postgres.yaml
kl apply -k ./ingress/shlink/
kl -n shlink get pod --output wide -L spilo-role
```

# Cleanup

```bash
kl delete -k ./ingress/shlink/
kl delete -f ./ingress/shlink/postgres.yaml
kl delete ns shlink
```

# CLI

```bash
# list available commands
kl -n shlink exec deployments/shlink -- shlink
# generate link with random value
kl -n shlink exec deployments/shlink -- shlink short-url:create -- https://example.com/
# generate link with predefined value
kl -n shlink exec deployments/shlink -- shlink short-url:create --custom-slug example -- https://example.com/
# remove previously generated link (useful for predefined links)
kl -n shlink exec deployments/shlink -- shlink short-url:delete -- example
# list all existing links
kl -n shlink exec deployments/shlink -- shlink short-url:list

# you can also add --domain <value> to any command to use a custom domain
```

# Setup ingress

- Wildcard ingress on the main domain

This setup uses the main domain directly, without a subdomain,
unlike other ingress configs in the repo.

```bash
kl label ns --overwrite shlink copy-wild-cert=main
kl apply -k ./ingress/shlink/ingress-wildcard/
kl -n shlink get ingress
```

- LetsEncrypt ingress on a custom domain

You can use a different domain (maybe you have a shorter one that isn't your main domain).
Maybe your short domain doesn't have wildcard support.

Make sure that your `letsencrypt-production` cluster issuer works without issues before deploying this.
When in doubt, edit ingress config to use `letsencrypt-staging` instead, and test it.

```bash
mkdir -p ./ingress/shlink/ingress-custom-letsencrypt/env/
cat <<EOF > ./ingress/shlink/ingress-custom-letsencrypt/env/domain.env
domain=my.domain.example
EOF

kl apply -k ./ingress/shlink/ingress-custom-letsencrypt/
kl -n shlink get ingress
kl -n shlink get certificate
kl -n shlink get secrets
```
