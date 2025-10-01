
# deploy

```bash

mkdir -p ./ingress/gateway-api/protected/env/

 cat << EOF > ./ingress/gateway-api/protected/env/gateway-class.env
# set to your preferred gateway class
gateway_class=istio
EOF

kl apply -k ./ingress/gateway-api/protected/

kl -n gateways get gateway main-protected
kl -n gateways describe gateway main-protected

kl -n gateways get gateway

```

# cleanup

```bash
kl delete -k ./ingress/gateway-api/protected/
```

# enforce oidc auth via istio config

```bash

cp ./ingress/gateway-api/protected/istio-auth-protected-policy.template.yaml ./ingress/gateway-api/protected/env/istio-auth-protected-policy.yaml
# manually edit the file and replace REPLACE_ME placeholders
# edit jwtRules, set your upstream issuer

kl apply -f ./ingress/gateway-api/protected/env/istio-auth-protected-policy.yaml

cp ./ingress/gateway-api/protected/istio-auth-allow.template.yaml ./ingress/gateway-api/protected/env/istio-auth-allow.yaml
# manually edit the file and replace REPLACE_ME placeholders

kl apply -f ./ingress/gateway-api/protected/env/istio-auth-allow.yaml

kl -n gateways get ap
kl -n gateways get ra

```
