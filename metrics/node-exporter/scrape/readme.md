
# Node exporter outside of k8s cluster

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

# make sure that you have "node_exporter" group is present in ansible inventory
ansible-inventory --graph node_exporter

ansible-playbook ./metrics/node-exporter/scrape/playbook.yaml

```

# Prometheus scrape config

```bash
mkdir -p ./metrics/node-exporter/scrape/env/

# if you already have scrape-patch.yaml, add more objects into staticConfigs list
 cat << EOF > ./metrics/node-exporter/scrape/env/scrape-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-node-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      location: cluster-name
    targets:
    - node1.example.com:9100
    - node2.example.com:9100
EOF

kl apply -k ./metrics/node-exporter/scrape/

```

# Manual metric checking

```bash

node=
curl -sS --insecure http://$node:9100/metrics > ./node-exporter.log

```
