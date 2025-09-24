
# Echo

This deployment returns info about incoming request.

# Deploy

```bash

kl create ns echo
kl label ns echo pod-security.kubernetes.io/enforce=baseline

kl apply -k ./test/echo/
kl -n echo get pod -o wide

kl apply -k ./test/echo/httproute-public/
# don't forget to add https://echo-protected-url/oauth2/callback to the list of allowed redirect URIs
kl apply -k ./test/echo/httproute-protected/
kl -n echo get htr
kl -n echo describe htr echo-public
kl -n echo describe htr echo-protected
kl -n gateways get ap

```

# Cleanup

```bash
kl delete -k ./test/echo/
kl delete ns echo
```
