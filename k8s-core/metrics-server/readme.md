
# Metrics server

References:
- https://github.com/kubernetes-sigs/metrics-server

# Generate config

```bash
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml -O ./k8s-core/metrics-server/secure/metrics-server.yaml
```

# Install

```bash

kl create ns metrics
kl label ns metrics pod-security.kubernetes.io/enforce=baseline

# if your cluster have proper TLS certificates
kl apply -k ./k8s-core/metrics-server/secure/
# if your cluster doesn't have proper TLS certificates
kl apply -k ./k8s-core/metrics-server/insecure/

kl -n metrics get pod -o wide

# check that metrics actually work
kl -n metrics top pod

```

# Cleanup

```bash
kl delete -k ./k8s-core/metrics-server/secure/
kl delete ns metrics
```
