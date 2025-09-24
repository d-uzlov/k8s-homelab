
# deploy

```bash

mkdir -p ./ingress/gateway-api/public/env/

 cat << EOF > ./ingress/gateway-api/public/env/gateway-class.env
# set to your preferred gateway class
gateway_class=istio
EOF

kl apply -k ./ingress/gateway-api/public/
kl -n gateways describe gateway main-public
kl -n gateways describe httproute http-redirect-public

kl -n gateways get gateway

```

# cleanup

```bash
kl delete -k ./ingress/gateway-api/public/
```

# enforce oidc auth via istio config

This is applicable only to gateways based on Istio.

You can skip this if you don't have setup for protected workloads.

```bash

cp ./ingress/gateway-api/public/istio-auth-protected-policy.template.yaml ./ingress/gateway-api/public/env/istio-auth-protected-policy.yaml
# manually edit the file and replace REPLACE_ME placeholders
# edit jwtRules, set your upstream issuer

kl apply -f ./ingress/gateway-api/public/env/istio-auth-protected-policy.yaml

cp ./ingress/gateway-api/public/istio-auth-allow.template.yaml ./ingress/gateway-api/public/env/istio-auth-allow.yaml
# manually edit the file and replace REPLACE_ME placeholders

kl apply -f ./ingress/gateway-api/public/env/istio-auth-allow.yaml

kl -n gateways get ap
kl -n gateways get ra

```
