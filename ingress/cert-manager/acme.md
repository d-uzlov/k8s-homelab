
# List of AMCE providers

* LetsEncrypt
  * Has relatively strict rate limits for production certificates
  * Can issue wildcard certificates via a DNS01 challenge.
* ZeroSSL
  * Website: https://zerossl.com
  * Doesn't declare any rate limits,
    but recently they have been added, and are apparently very severe.
    There is no official documentation at the moment of writing this.
    https://github.com/cert-manager/cert-manager/issues/5867
  * Doesn't work with `.ru` zone
    https://habr.com/ru/companies/itsumma/news/571368/#comment_24421522
  * Allegedly can issue wildcard certificates.
  * The official limit is 3 certs per free account, but it doesn't seem to apply to ACME.
* Buypass-Go-SSL
  * Doesn't work from Russia
* SSL.com
  * Website: SSL.com
  * Guide: https://habr.com/ru/companies/itsumma/news/571368/
  * Needs manual registration

# Letsencrypt rate limits

Staging issuer has some unspecified high limits.

Production issuer has the following limits:
- Certificates per Registered Name: 50 per week
  - Registered Domain is a `<subdomains>.<registered-name>.<register-domain>`.
  - `<register-domain>` is a parent domain, like `com`, `net`, `co.uk`, etc.
  - Fortunately, `duckdns.org` is in the list of register domains,
  so things like `my-domain.duckdns.org` and `another-domain.duckdns.org`
  are considered separate domains and don't share a rate limit.
  - However, `app.my-domain.duckdns.org` and `cloud.my-domain.duckdns.org` share the limit.
  - This is better explained here: https://publicsuffix.org.
  Also, that website has a list of all `<register-domain>` possible values.
- New Orders per account: 300 per 3 hours
- Duplicate Certificate: 5 per week
- Failed Validation limit: 5 failures per account, per hostname, per hour.
  This limit is higher on staging environment
- Accounts per IP Address: 10 per 3 hours

An account is registered by cert-manager when you create a new Issuer or a ClusterIssuer
https://cert-manager.io/docs/configuration/acme/
It's possible to reuse the old account if you have its key.
