
# Deploy

```bash
kl create ns ingress-test

# deploy echo server
kl apply -f ./test/ingress/echo.yaml
# deploy echo server for control plane
kl apply -f ./test/ingress/echo-cp.yaml

kl -n ingress-test get pod

# depoy different ingress resources
kl label ns --overwrite ingress-test copy-wild-cert=main
kl apply -k ./test/ingress/wildcard/
kl apply -k ./test/ingress/http01/

# deploy load balancer service
kl apply -k ./test/ingress/loadbalancer/
# check loadbalancer
kl -n ingress-test get svc echo-lb
curl $(kl -n ingress-test get svc echo-lb -o go-template --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")

# check out if HSTS is enabled
# (this repo uses settings to disable it)
# If you see something like this, HSTS is enabled:
#   strict-transport-security: max-age=15724800; includeSubDomains
test_domain=$(kl -n ingress-test get ingress echo-wildcard -o go-template --template="{{range .spec.rules}}{{.host}}{{end}}")
curl "https://$test_domain/" && ! curl -s -D- "https://$test_domain/" | grep strict-transport-security
```

# Cleanup

```bash
kl delete -k ./test/ingress/wildcard
kl delete -k ./test/ingress/http01/
kl delete -k ./test/ingress/loadbalancer/

kl delete -f ./test/ingress/echo.yaml
kl delete -f ./test/ingress/echo-cp.yaml

kl delete ns ingress-test
```
