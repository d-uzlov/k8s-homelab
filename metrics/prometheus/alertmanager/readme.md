

# alertmanager

References:
- https://github.com/prometheus/alertmanager/releases
- https://github.com/prometheus/alertmanager/blob/main/template/default.tmpl
- https://github.com/prometheus/alertmanager/blob/main/doc/examples/simple.yml

# Deploy

```bash

kl apply -k ./metrics/prometheus/alertmanager/
kl -n prometheus get pod -o wide

# private gateway
kl apply -k ./metrics/prometheus/alertmanager/httproute/
kl apply -k ./metrics/prometheus/alertmanager/httproute-protected/
kl -n prometheus get httproute
kl -n prometheus describe httproute alertmanager

```

To use alertmanager, create an `AlertmanagerConfig` object with `alertmanager.prometheus.io/instance: main` label.
For example:
- [telegram](./notify-telegram.md)

# Cleanup

```bash
kl delete -k ./metrics/alertmanager/
```

# Manual metric checking

```bash
kl -n prometheus describe svc alertmanager
kl exec deployments/alpine -- curl -sS http://alertmanager.prometheus:9093/metrics
kl exec deployments/alpine -- curl -sS http://alertmanager.prometheus:8080/metrics
```
