
# Deploy

```bash
# deploy echo server
kl apply -f ./test/ingress/echo.yaml
# deploy echo server for control plane
kl apply -f ./test/ingress/echo-cp.yaml

# depoy different ingress resources
kl label ns --overwrite default copy-wild-cert=main
kl apply -k ./test/ingress/wildcard/
kl apply -k ./test/ingress/http01/
# deploy load balancer service
kl apply -k ./test/ingress/loadbalancer/

# check out if HSTS is enabled
# (this repo uses settings to disable it)
test_domain=$(kl get ingress echo-wildcard -o go-template --template="{{range .spec.rules}}{{.host}}{{end}}")
curl "https://$test_domain/" && ! curl -s -D- "https://$test_domain/" | grep strict-transport-security
```

# Cleanup

```bash
kl delete -k ./test/ingress/wildcard
kl delete -k ./test/ingress/http01/
kl delete -k ./test/ingress/loadbalancer/

kl delete -f ./test/ingress/echo.yaml
kl delete -f ./test/ingress/echo-cp.yaml
```
