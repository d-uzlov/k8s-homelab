
# vector

References:
- https://github.com/vectordotdev/vector

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

# you can use this to check and adjust journal size on nodes
sudo journalctl --disk-usage
sudo journalctl --rotate
sudo journalctl --vacuum-time=14d

ansible-inventory --graph journald
ansible-playbook ./metrics/victoria-metrics/vector/external/journald-playbook.yaml

ansible-inventory --graph logs_vector_in_docker
ansible-playbook ./metrics/victoria-metrics/vector/external/playbook.yaml

```

# Manual metric checking

```bash

node=debian-ws.k8s.lan
curl http://$node:9090/metrics > ./vector.prom

```
