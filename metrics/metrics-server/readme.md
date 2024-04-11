
# Metrics server

References:
- https://github.com/kubernetes-sigs/metrics-server

# Install

```bash
kl create ns metrics
kl label ns metrics pod-security.kubernetes.io/enforce=baseline

# if your cluster have proper TLS certificates
kl apply -k ./metrics/metrics-server/secure/
# if your cluster doesn't have proper TLS certificates
kl apply -k ./metrics/metrics-server/insecure/

kl -n metrics get pod -o wide

# check that metrics actually work
kl -n metrics top pod
```

# Cleanup

```bash
kl delete -k ./metrics/metrics-server/secure/
kl delete ns metrics
```
