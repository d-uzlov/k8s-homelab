
# List of ACME providers

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
  - Registered Domain is the last component before last public suffix
  - For example: `<subdomain>.<registered-name>.<register-domain>`.
  - `<register-domain>` is a parent domain, like `com`, `net`, `co.uk`, etc.
  - Subdomains share the limit.
  - This is better explained here: https://publicsuffix.org.
  Also, that website has a list of all `<register-domain>` possible values.
- New Orders per account: 300 per 3 hours
- Duplicate Certificate: 5 per week
- Failed Validation limit: 5 failures per account, per hostname, per hour.
  This limit is higher on staging environment
- Accounts registration: 10 per 3 hours per IP Address

An account is registered by cert-manager when you create a new Issuer or a ClusterIssuer
https://cert-manager.io/docs/configuration/acme/
It's possible to reuse the old account if you have its key.

# List of public DNS suffixes

Also known as "Register domains" as per Letsencrypt.

References:
- https://github.com/publicsuffix/list/blob/master/public_suffix_list.dat

# ACME delegation for DNS01

References:
- https://letsencrypt.org/docs/challenge-types/
- https://community.letsencrypt.org/t/help-me-understand-acme-dns/58892/24

When doing DNS01 challenge, Letsencrypt queries
`_acme-challenge.example.domain` for TXT records.
You can delegate this domain for a separate DNS server.

You can create roughly the following to do the delegation:

```dns
_acme-challenge.example.com CNAME a2f7df8a-e3d6-4225-a130-5ed56a1db8f3.acme.example.com
acme.example.com NS ns1.acme.example.com
ns1.acme.example.com A 1.2.3.4
```

Letsencrypt will find the `_acme-challenge` CNAME redirect,
follow it through the corresponding NS record,
resolve the NS record via the corresponding A record,
and finally query the corresponding DNS server via the resolved IP.

NS and the corresponding A records are optional.

More info on how to get the CNAME address and set up validation is here:
[acme-dns](./acme-dns/readme.md)
