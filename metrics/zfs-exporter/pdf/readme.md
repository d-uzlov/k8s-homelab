
# ZFS exporter outside of k8s cluster

References:
- https://github.com/pdf/zfs_exporter

# Prerequisites

- [Ansible](../../../docs/ansible.md)

Also download exporter binary:

```bash

# https://github.com/pdf/zfs_exporter/releases
zfs_exporter_version=2.3.8

wget --directory-prefix ./metrics/zfs-exporter/pdf/env/ https://github.com/pdf/zfs_exporter/releases/download/v${zfs_exporter_version}/zfs_exporter-${zfs_exporter_version}.linux-amd64.tar.gz
tar zxv -f ./metrics/zfs-exporter/pdf/env/zfs_exporter-${zfs_exporter_version}.linux-amd64.tar.gz -C ./metrics/zfs-exporter/pdf/env/

```

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

# make sure that you have "zfs" group is present in ansible inventory
ansible-inventory --graph zfs

ansible-playbook ./metrics/zfs-exporter/pdf/playbook.yaml

```

# Post-install checks

```bash

sudo systemctl daemon-reload
sudo systemctl restart pdf_zfs_exporter

systemctl status --no-pager pdf_zfs_exporter.service
sudo journalctl -b -u pdf_zfs_exporter

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/zfs-exporter/pdf/env/

[ -f ./metrics/zfs-exporter/pdf/env/targets-patch.yaml ] ||
  cp ./metrics/zfs-exporter/pdf/scrape-patch.template.yaml ./metrics/zfs-exporter/pdf/env/scrape-patch.yaml

# adjust location to your needs
# if scrape-patch.yaml already exists, add more items into staticConfigs list
 cat << EOF >> ./metrics/zfs-exporter/pdf/env/scrape-patch.yaml
 ---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-zfs-exporter
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  staticConfigs:
  - labels:
      job: zfs-exporter
      location: cluster-name
    targets:
    - node1.example.com:9134
    - node2.example.com:9134
EOF

kl apply -k ./metrics/zfs-exporter/pdf/
kl -n prometheus describe scrapeconfig external-zfs-exporter

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/pdf/
```

# Manual metric checking

```bash

node=
curl -sS --insecure http://$node:9134/metrics > ./zfs-exporter-pdf.log

```

# Alerts

References:
- https://samber.github.io/awesome-prometheus-alerts/rules.html#zfs
