
# prometheus

References:
- https://github.com/prometheus/prometheus/releases

# Prerequisites

- [Prometheus Operator](../prometheus-operator/readme.md)

# Deploy

```bash

kl create ns prometheus
kl label ns prometheus pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/prometheus/

```

Don't forget ro deploy child resources:
- [generic prometheus](./main/readme.md)
- [prompp prometheus](./prompp/readme.md)
- [alertmanager](./alertmanager/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/prometheus/
kl delete ns prometheus
```

# Useful commands

```bash

kl api-resources | grep coreos

# show list of all relevant prometheus configs
kl get promrule -A
kl get smon -A
kl get pmon -A
kl get scfg -A
kl get probe -A

```
