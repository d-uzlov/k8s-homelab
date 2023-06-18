
# Cert-manager

This is an app to automatically create and update certificates
by automatically issuing them from any ACME-compatible certificate provider.

# Deploy

```bash
# Generate deployment
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm template \
  cert-manager jetstack/cert-manager \
  --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' \
  --version v1.11.0 \
  --namespace cert-manager \
  --set installCRDs=false \
  > ./ingress/cert-manager/cert-manager.yaml

kl create ns cert-manager
kl apply -k ./ingress/cert-manager
```

There are several ready-to-use issuers:
- [DuckDNS (DNS-01 challenge with duckdns domains)](./duckdns/)
- [LetsEncrypt (HTTP-01 challenge)](./letsencrypt/)

# Ingress with single-domain certificates

Add an annotation to the ingress:
```yaml
# for namespaced issuers
cert-manager.io/issuer: issuer-name
# for cluster-wide issuers
cert-manager.io/cluster-issuer: issuer-name
```

Change issuer name accordingly.

Certificate will be automaticelly issued and injected into the Ingress resource.

# Wildcard certificate

You need to deploy following resources:
- [DuckDNS webhook](./duckdns/)
- [Replicator](../replicator/)
- [Manually create a certificate](../manual-certificates/)

Manual certificate deployment also has instructions on how to use the certificate.

# Error handling

Ingress creates a new certificate if requested certificate currently doesn't exist.
Certificates are kept as a k8s secrets.

If you create a certificate with incorrect settings,
then change the settings, but keep the secret name the same,
it will not be automatically reissued with new settings.
You need to either change the secret name or delete the old secret.

# Browser error handling

If you have opened the web page with a wrong certificate, the certificate may be cached.
Even if you update the certificate on the server side, the client won't see it.

You need to clear browser cache to pick up the new certificate.
You may also need to restart the browser after clearing the cache.

# List of AMCE providers

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
