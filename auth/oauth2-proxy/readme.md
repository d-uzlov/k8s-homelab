
# oauth2-proxy

References:
- https://github.com/oauth2-proxy/oauth2-proxy
- https://medium.com/@lucario/istio-external-oidc-authentication-with-oauth2-proxy-5de7cd00ef04

# config

```bash

mkdir -p ./auth/oauth2-proxy/env/

# create cookie secret
openssl rand -hex 16

 cat << EOF > ./auth/oauth2-proxy/env/secret.env
issuer=https://dex.example.com/
client-id=oauth2-proxy
client-secret=456
cookie-secret=123
EOF

```

# deploy

```bash

kl create ns auth-oauth2-proxy
kl label ns auth-oauth2-proxy pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/oauth2-proxy/
kl -n auth-oauth2-proxy get pod -o wide

```

# cleanup

```bash
kl delete -k ./auth/oauth2-proxy/
kl delete ns auth-oauth2-proxy
```

# istio mesh config

Add this to your istio mesh config:

```yaml
extensionProviders:
- name: oauth2-proxy
  envoyExtAuthzHttp:
    service: oauth2-proxy.auth-oauth2-proxy.svc.cluster.local
    port: '80'
    includeHeadersInCheck: [ "authorization", "cookie", "x-auth-request-access-token" ]
    headersToUpstreamOnAllow:
    - authorization
    - path
    - x-auth-request-*
    headersToDownstreamOnDeny: [ "content-type", "set-cookie" ]
```
