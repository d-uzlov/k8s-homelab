
# Echo

This deployment returns info about incoming request.

# Deploy

```bash

kl create ns echo
kl label ns echo pod-security.kubernetes.io/enforce=baseline

kl apply -k ./test/echo/
kl -n echo get pod -o wide

kl apply -k ./test/echo/httproute-public/
kl apply -k ./test/echo/httproute-protected/
kl -n echo get httproute
kl -n gateways get authorizationpolicy

```

# Cleanup

```bash
kl delete -k ./test/echo/
kl delete ns echo
```
