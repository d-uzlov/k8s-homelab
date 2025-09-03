
# etcd cluster

This file provides instructions to create an etcd cluster.
The main intent is to use it as an external etcd for k8s.

References:
- https://etcd.io/docs/v3.3/op-guide/clustering/
- https://github.com/etcd-io/etcd/tree/main/hack/tls-setup

# Prerequisites

- 1 or 3 VMs or LXC containers dedicated to etcd
- - 1 is no redundancy, 2 is still no redundancy, with 3 instances one may fail without affecting clients
- Network connectivity between hosts, L3 should be enough
- DNS records for all etcd hosts

# Installation

References:
- https://etcd.io/docs/v3.3/install/
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://docs.ondat.io/docs/prerequisites/etcd/etcd-outside-the-cluster/

Execute on each etcd node:

```bash

# make sure that you have "test-etcd" group is present in ansible inventory
ansible-inventory --graph test-etcd

# run on a single host when upgrading
# don't forget to consult upgrade guide before running this
ansible-playbook ./k8s-core/docs/etcd/etcd-playbook.yaml --limit "k8s1-etcd3.k8s.lan"

```

# Setup aliases

```bash

cluster_name=
node1=k8s1-etcd1.k8s.lan
node2=k8s1-etcd2.k8s.lan
node3=k8s1-etcd3.k8s.lan

 cat << EOF > ~/.bashrc.d/etcd-aliases.sh
# you may want to add this to your bashrc
alias etcdctl_cluster="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:2379,https://$node2:2379,https://$node3:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node1="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node2="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node2:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node3="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node3:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"
EOF

```

# Test connection

```bash

etcdctl_cluster member list -w table
etcdctl_cluster endpoint status -w table
etcdctl_cluster endpoint health -w table

```

# Disaster recovery

Imagine `k8s1-etcd1.k8s.lan` is unavailable.
Cluster is still working but is unhealthy.
You need to replace it with a new node, or just reinitialize the old one.
The process is the same for both cases.

Adjust node names and addresses appropriately.

```bash

alias etcdctl="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node2:2379,https://$node3:2379 \
  --cacert=./k8s-core/docs/etcd/env/ca.pem \
  --cert=./k8s-core/docs/etcd/env/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/etcd-client-key.pem"

etcdctl member list -w table
# replace ID with your value
etcdctl member remove b5a71f0b96b3191f

# on the existing member node
systemctl stop etcd3
rm -rf /var/lib/etcd/
nano /etc/systemd/system/etcd3.service
# change --initial-cluster-state=new to --initial-cluster-state=existing

# for a new node, init it as usual and then run steps above

# choose any name, here I just reuse the old name
# set correct URL for your new node
etcdctl member add k8s1-etcd1.k8s.lan --peer-urls=https://k8s1-etcd1.k8s.lan:2380

# on the member node
systemctl restart etcd3

```

# Shrink etcd DB

```bash

etcdctl_cluster endpoint status --write-out=json | jq .
# check database size
etcdctl_cluster endpoint status --write-out=json | jq .[].Status.dbSize | numfmt --to=iec

# get current cluster revision
etcdctl_cluster endpoint status --write-out=json | jq .[].Status.header.revision
# substitute your revision
etcdctl_cluster compact 816183644

# defrag one node at a time
etcdctl_node1 defrag
etcdctl_node2 defrag
etcdctl_node3 defrag

```
