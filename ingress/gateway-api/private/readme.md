
# deploy

```bash

mkdir -p ./ingress/gateway-api/private/env/

 cat << EOF > ./ingress/gateway-api/private/env/gateway-class.env
# set to your preferred gateway class
gateway_class=istio
EOF

kl apply -k ./ingress/gateway-api/private/
kl -n gateways describe gateway main-private
kl -n gateways describe httproute http-redirect-private

kl -n gateways get gateway

```

# cleanup

```bash
kl delete -k ./ingress/gateway-api/private/
```
