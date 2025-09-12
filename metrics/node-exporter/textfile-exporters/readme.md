
# textfile exporters

References:
- https://github.com/prometheus-community/node-exporter-textfile-collector-scripts

# Prerequisites

- [Ansible](../../../docs/ansible.md)

# install via ansible

```bash

ansible-inventory --graph node_textfile

ansible-playbook ./metrics/node-exporter/textfile-exporters/playbook.yaml

```

# Update scripts

```bash

apt_info_url=https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/raw/refs/heads/master/apt_info.py

wget -O ./metrics/node-exporter/textfile-exporters/apt_info.py "$apt_info_url"
chmod +x ./metrics/node-exporter/textfile-exporters/apt_info.py

```
