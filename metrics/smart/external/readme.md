
# smartctl-exporter

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

# make sure that you have "smartctl_exporter" group is present in ansible inventory
ansible-inventory --graph smartctl_exporter

ansible-playbook ./metrics/smart/external/playbook.yaml

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/smart/external/env/

# adjust location to your needs
# repeat if you need to scrape several clusters with different names
 cat << EOF > ./metrics/smart/external/env/scrape-smartctl.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-smart
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  scrapeTimeout: 1s
  staticConfigs:
  - labels:
      location: my-cluster
    targets:
    - example.com:9633
  - labels:
      location: my-cluster
      ok_to_be_missing: 'true'
    targets:
    - volatile-example.com:9633
  relabelings:
  - targetLabel: instance
    sourceLabels: [ __address__ ]
    regex: (.*):\d*
    action: replace
  - action: replace
    targetLabel: job
    replacement: smartctl-exporter
  metricRelabelings:
  - action: labeldrop
    # this should be in metricRelabelings, so up{} metric doesn't lose it
    regex: ok_to_be_missing
  - action: drop
    sourceLabels: [ __name__ ]
    regex: go_gc_.*|process_.*
EOF

kl apply -f ./metrics/smart/external/env/scrape-smartctl.yaml
kl -n prometheus describe scrapeconfig external-smart

```

# Manual metric checking

```bash

node=
curl -sS --insecure http://$node:9633/metrics > ./smartctl-exporter.log

```
