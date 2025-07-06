
# prometheus

References:
- https://github.com/deckhouse/prompp/releases

# Prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)

# Prompp deploy

```bash

kl apply -k ./metrics/prometheus/prompp/
kl -n prometheus get pod -o wide

kl -n grafana apply -k ./metrics/prometheus/prompp/grafana-datasource/

kl apply -k ./metrics/prometheus/prompp/httproute-private/
kl -n prometheus get htr

```

To use this prometheus instance with `ServiceMonitor` and other resources,
add `instance.prometheus.io/prompp: enable` label to them.
Prometheus monitors all namespaces for these objects.

# Cleanup

```bash
kl delete -k ./metrics/prometheus/prompp/
# kl delete ns prometheus
```
