
# cadvisor metrics

This cadvisor deployment is not standalone nodes.

References:
- https://github.com/google/cadvisor

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

ansible-inventory --graph cadvisor

# start/restart of cadvisor container can be a bit slow, give it a minute
ansible-playbook ./metrics/cadvisor/cadvisor-external/playbook.yaml

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/cadvisor/cadvisor-external/env/

location=

# adjust tags to your needs
# if scrape-patch.yaml already exists, add more items into staticConfigs list

 cat << EOF > ./metrics/cadvisor/cadvisor-external/env/scrape-cadvisor-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: cadvisor-external
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  # you may want to increase the timeout for large or slow targets
  scrapeTimeout: 1s
  staticConfigs:
  - labels:
      location: $location
    targets:
    - node1.example.com:8999
    - node2.example.com:8999
EOF

kl apply -k ./metrics/cadvisor/cadvisor-external/
kl -n metrics-cadvisor describe scrapeconfig cadvisor-external

```

# Cleanup

```bash
kl delete -k ./metrics/cadvisor/cadvisor-external/
```

# Manual metric checking

```bash

node=
curl -sS http://$node:8999/metrics > ./cadvisor.prom

```
