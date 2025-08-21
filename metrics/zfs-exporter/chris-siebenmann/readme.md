
# ZFS exporter outside of k8s cluster

References:
- https://github.com/siebenmann/zfs_exporter

# Prerequisites

- [Ansible](../../../docs/ansible.md)
- [Golang](../../../docs/golang.md#install)

Also compile exporter binary locally:

```bash

# download repository
( cd ./metrics/zfs-exporter/chris-siebenmann/env/; git clone --depth 1 -b cks-upstream https://github.com/siebenmann/zfs_exporter.git; )
# build exporter binary
( cd ./metrics/zfs-exporter/chris-siebenmann/env/zfs_exporter/; CGO_ENABLED=0 go build -ldflags="-w -s" -o zfs-exporter-chris main.go; )

```

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

# make sure that you have "zfs" group is present in ansible inventory
ansible-inventory --graph zfs

ansible-playbook ./metrics/zfs-exporter/chris-siebenmann/playbook.yaml

```

# Post-install checks

```bash

sudo systemctl daemon-reload
sudo systemctl restart chris_zfs_exporter
systemctl status --no-pager chris_zfs_exporter.service
sudo journalctl -b -u chris_zfs_exporter

```

# Prometheus scrape config

```bash

mkdir -p ./metrics/zfs-exporter/chris-siebenmann/env/

# adjust location to your needs
# if scrape-patch.yaml already exists, add more items into staticConfigs list
 cat << EOF > ./metrics/zfs-exporter/chris-siebenmann/env/scrape-patch.yaml
 ---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-zfs-exporter-chris
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
    - node1.example.com:9700
    - node2.example.com:9700
EOF

kl apply -k ./metrics/zfs-exporter/chris-siebenmann/
kl -n prometheus describe scrapeconfig external-zfs-exporter-chris

```

# Cleanup

```bash
kl delete -k ./metrics/zfs-exporter/chris-siebenmann/
```

# Manual metric checking

```bash

node=nas-tulip.storage.lan
curl -sS --insecure http://$node:9700/metrics > ./zfs-exporter-chris.log

```
