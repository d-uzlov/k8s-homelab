
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
kl -n gateways describe tlsroute protected-tls-redirect

kl -n gateways get gateway

```

# cleanup

```bash
kl delete -k ./ingress/gateway-api/public/
```
