
# httpbin

# Deploy

```bash

kl create ns httpbin
kl label ns httpbin pod-security.kubernetes.io/enforce=baseline

kl apply -k ./test/httpbin/
kl -n httpbin get pod -o wide

kl apply -k ./test/httpbin/httproute-public/
kl -n httpbin get httproute

```

# Cleanup

```bash
kl delete -k ./test/httpbin/
kl delete ns httpbin
```
