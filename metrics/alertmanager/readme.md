

# alertmanager

References:
- https://github.com/prometheus/alertmanager/releases

# Prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)

# Deploy

```bash

kl create ns alertmanager
kl label ns alertmanager pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/alertmanager/
kl -n alertmanager get pod -o wide

# private gateway
kl apply -k ./metrics/alertmanager/httproute/
kl -n alertmanager get httproute alertmanager
kl -n alertmanager describe httproute alertmanager

```

# Cleanup

```bash
kl delete -k ./metrics/alertmanager/
kl delete ns alertmanager
```

# Manual metric checking

```bash
kl -n alertmanager describe svc alertmanager
kl exec deployments/alpine -- curl -sS http://alertmanager.alertmanager:9093/metrics
kl exec deployments/alpine -- curl -sS http://alertmanager.alertmanager:8080/metrics
```
