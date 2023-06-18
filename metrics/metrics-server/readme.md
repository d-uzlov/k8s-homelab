
https://github.com/kubernetes-sigs/metrics-server

# Metrics server

# Requirements

You either need to disable tls verification or add certificates.

Look here for instructions to add certificates: [kubelet-csr-approver](../kubelet-csr-approver/).

# Install

```bash
kl create ns metrics
kl apply -k ./metrics/metrics-server/
```
