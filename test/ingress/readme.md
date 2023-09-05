
# Deploy

```bash
# deploy echo server
kl apply -f ./test/ingress/echo.yaml
# deploy echo server for control plane
kl apply -f ./test/ingress/echo-cp.yaml

# depoy different ingress resources
kl apply -k ./test/ingress/wildcard
kl apply -k ./test/ingress/http01/
# deploy load balancer service
kl apply -k ./test/ingress/loadbalancer/
```

# Cleanup

```bash
kl delete -k ./test/ingress/wildcard
kl delete -k ./test/ingress/http01/
kl delete -k ./test/ingress/loadbalancer/

kl delete -f ./test/ingress/echo.yaml
kl delete -f ./test/ingress/echo-cp.yaml
```
