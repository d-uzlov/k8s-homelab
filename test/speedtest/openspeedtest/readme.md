
# openspeedtest

References:
- https://github.com/openspeedtest/Docker-Image
- https://hub.docker.com/r/openspeedtest/latest

Issues:

- For ingress it shows unlimited upload speed
- For gateway it show very slow upload speed

Apparently, it could be fixed by using HTTP 1.1 instead of HTTP 2.0.
But it's impossible to disable http2 for a single ingress.

# Deploy

```bash

kl create ns openspeedtest
kl label ns openspeedtest pod-security.kubernetes.io/enforce=baseline

# setup wildcard ingress
kl label ns --overwrite openspeedtest copy-wild-cert=main
kl apply -k ./test/speedtest/openspeedtest/ingress-wildcard/
kl -n openspeedtest get ingress

# setun loadbalancer
kl apply -k ./test/speedtest/openspeedtest/loadbalancer/
kl -n openspeedtest get svc lb

kl apply -k ./test/speedtest/openspeedtest/httproute/
kl -n openspeedtest get httproute openspeedtest
kl -n openspeedtest describe httproute openspeedtest

kl apply -k ./test/speedtest/openspeedtest/
kl -n openspeedtest get pod -o wide

```

# Cleanup

```bash
kl delete -k ./test/speedtest/openspeedtest/
kl delete -k ./test/speedtest/openspeedtest/ingress-wildcard/
kl delete -k ./test/speedtest/openspeedtest/httproute/
kl delete -k ./test/speedtest/openspeedtest/loadbalancer/
kl delete ns openspeedtest
```
