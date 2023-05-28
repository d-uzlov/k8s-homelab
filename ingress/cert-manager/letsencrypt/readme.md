
# LetsEncrypt

This deployment just adds LetsEncrypt issuers to the cluster.

These issuers use HTTP-01 challenge:
- They are fully automatic, no additional config needed
- They need port 80 to be opened in the ingress.
- They must point to exact domain name, wildcard certificates are not supported

# Deploy

```bash
# Init once
mkdir -p ./ingress/cert-manager/letsencrypt/env
echo <<EOF > ./ingress/cert-manager/letsencrypt/env/letsencrypt.env
# Can be any valid email.
# You will get a warning email from letsencrypt
# if you forget to update you certificate.
email=example@example.com
EOF

kl apply -k ./ingress/cert-manager/letsencrypt
```

# Letsencrypt rate limits

Staging issuer has some unspecified high limits.

Production issuer has the following limits:
- Certificates per Registered Domain: 50 per week
  - Registered Domain is a `<subdomains>.<registered-name>.<register-domain>`.
  - `<register-domain>` is a parent domain, like `com`, `net`, `co.uk`, etc.
  - Fourtunately, `duckdns.org` is in the list of register domains,
  so things like `my-domain.duckdns.org` and `another-domain.duckdns.org`
  are considered separate domains and don't share a rate limit.
  - However, `app.my-domain.duckdns.org` and `cloud.my-domain.duckdns.org` share the limit.
  - This is better explained here: https://publicsuffix.org.
  Also that website has a list of all `<register-domain>` possible values.
- New Orders per account: 300 per 3 hours
- Duplicate Certificate: 5 per week
- Failed Validation limit: 5 failures per account, per hostname, per hour.
  This limit is higher on staging environment
- Accounts per IP Address: 10 per 3 hours

An account is registered by cert-manager when you create a new Issuer or a ClusterIssuer
https://cert-manager.io/docs/configuration/acme/
It's possible to reuse the old account if you have its key.
