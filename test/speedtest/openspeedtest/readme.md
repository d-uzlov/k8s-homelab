
# openspeedtest

References:
- https://github.com/openspeedtest/Docker-Image
- https://hub.docker.com/r/openspeedtest/latest

# Deploy

```bash
kl create ns openspeedtest

# setup wildcard ingress
kl label ns --overwrite openspeedtest copy-wild-cert=main
kl apply -k ./test/speedtest/openspeedtest/ingress-wildcard/
kl -n openspeedtest get ingress

# setun loadbalancer
kl apply -k ./test/speedtest/openspeedtest/loadbalancer/
kl -n openspeedtest get svc lb

kl apply -k ./test/speedtest/openspeedtest/
kl -n openspeedtest get pod
```

# Issues

This test seems to show unlimited upload speed for some reason.
For example: DL 950, UL 120000, while the physical network is 1 GBit/s.

Also it seems to automatically upload results to `openspeedtest.com`.

Apparently this is caused by http2, but it's impossible to disable http2 for one ingress only,
it needs to be disabled globally for the whole ingress controller.
