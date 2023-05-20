
# Deploy cert-manager

kl apply -f ./ingress/cert-manager-1.11/cert-manager.yaml
kl apply -f ./ingress/cert-manager-1.11/issuers/letsencrypt-staging.yaml
kl apply -f ./ingress/cert-manager-1.11/issuers/letsencrypt-production.yaml

# Install

download CRDs:
```bash
wget https://github.com/cert-manager/cert-manager/releases/download/v1.11.1/cert-manager.crds.yaml
```

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm template \
  cert-manager jetstack/cert-manager \
  --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' \
  --version v1.11.0 \
  --set installCRDs=false
  > ./ingress/cert-manager/cert-manager.yaml
```

# Ingress settings

Select a proper issuer.
The `Issuer` is namespaced.
Use `ClusterIssuer` for cluster-wide deployment.

```yaml
cert-manager.io/cluster-issuer: letsencrypt-staging
```

# Wildcard certificate

```bash
kl apply -k ./ingress/cert-manager/duckdns
kl apply -k ./ingress/replicator

# edit certificate info and add more certificates
kl create ns certificates
kl apply -k ./ingress/manual-certificates
```

Then annotate namespaces that need to use this wildcard certificate.
Use matching label in certificate secret template and in command.
For example:

```bash
kl label ns nextcloud copy-wild-cert=example
```

Edit ingress resource:
Remove issuer annotation.
Set `spec.tls[].secretName` to match secret name from certificate spec.

# Error handling

Ingress issues a new certificate if it currently doesn't exist.
Certificate is kept in a k8s secret.

If you create a certificate with incorrect settings,
it will not be automatically reissued with new settings.
You need to either change the secret name or delete the old secret.

# Browser error handling

If you have opened the web page with a wrong certificate, the certificate is cached.
Even if you update the certificate on the server side, the client won't see it.

You need to clear browser cache to pick up the new certificate.
You may also need to restart the browser after clearing the cache.

# Letsencrypt rate limits

- Certificates per Registered Domain: 50 per week
  Registered Domain is a `<subdomains>.<registered-name>.<register-domain>`.`
  `<register-domain>` is a parent domain, like `com`, `net`, `co.uk`, etc.
  Fourtunately, `duckdns.org` is in the list of register domains,
  so things like `my-domain.duckdns.org` and `another-domain.duckdns.org`
  are considered separate domains and don't share a rate limit.
  However, `app.my-domain.duckdns.org` and `cloud.my-domain.duckdns.org` share the limit.

  This is better explained here: https://publicsuffix.org
  Also that website has a list of all `<register-domain>` possible values.
- New Orders per account: 300 per 3 hours
- Duplicate Certificate: 5 per week
- Failed Validation limit: 5 failures per account, per hostname, per hour.
  This limit is higher on our staging environment
- Accounts per IP Address: 10 per 3 hours

An account is registered by cert-manager when you create a new Issuer or a ClusterIssuer
https://cert-manager.io/docs/configuration/acme/
It's possible to reuse the old account if you have its key.

You should use the staging issuer first to make sure that there are no issues.
If there are any issues they won't affect the production issuer rate limits.

# Alt AMCE providers

* LetsEncrypt
  * Rate limits described above
  * Can issue wildcard certificates via a DNS01 challenge.
* ZeroSSL
  * Website: https://zerossl.com
  * Doesn't declare any rate limits,
    but recently they have been added, and are apprently very severe.
    There is no official documentation at the moment of writing this.
    https://github.com/cert-manager/cert-manager/issues/5867
  * Doesn't work with `.ru` zone
    https://habr.com/ru/companies/itsumma/news/571368/#comment_24421522
  * Allegedly can issue wildcard certificates.
  * The official limit is 3 certs per free account, but it doesn't seem to apply to ACME.
* Buypass Go SSL
  * Doesn't work from Russia
* SSL.com
  * Website: SSL.com
  * Guide: https://habr.com/ru/companies/itsumma/news/571368/
  * Needs manual registration
