
# textfile exporters

References:
- https://github.com/prometheus-community/node-exporter-textfile-collector-scripts

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

# make sure that you have "node_textfile" group is present in ansible inventory
ansible-inventory --graph node_textfile

ansible-playbook ./metrics/node-exporter/textfile-exporters/playbook.yaml

```

# Update scripts

```bash

wget -O ./metrics/node-exporter/textfile-exporters/apt_info.py https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/raw/refs/heads/master/apt_info.py
chmod +x ./metrics/node-exporter/textfile-exporters/apt_info.py

```
