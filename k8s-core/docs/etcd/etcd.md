
# etcd cluster

This file provides instructions to create an etcd cluster.
The main intent is to use it as an external etcd for k8s.

References:
- https://etcd.io/docs/v3.3/op-guide/clustering/
- https://github.com/etcd-io/etcd/tree/main/hack/tls-setup

# Prerequisites

- 1 or 3 VMs or LXC containers dedicated to etcd
- - 1 is no redundancy, 2 is still no redundancy, with 3 instances one may fail without affecting clients
- - It's possible to run etcd in docker but I think creating a VM with a single container inside is overengineering
- Network connectivity between hosts, L3 should be enough
- DNS records for all etcd hosts

# Installation

References:
- https://etcd.io/docs/v3.3/install/
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://docs.ondat.io/docs/prerequisites/etcd/etcd-outside-the-cluster/

Execute on each etcd node:

```bash

ETCD_VER=v3.5.13
wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"
tar zxf "etcd-${ETCD_VER}-linux-amd64.tar.gz"
mv "etcd-${ETCD_VER}-linux-amd64"/etcd* /usr/local/bin/
rm -rf etcd*

```

Later we will create a unique config file for each node, to create a cluster.

# TLS setup

While etcd can operate without any encryption, it also supports mTLS.
Kubeadm by default sets up etcd with encryption. Systemd config above also enables it.

```bash

# install cfssl
wget -q --show-progress \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64 \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64

mv cfssl_* cfssl
mv cfssljson_* cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/

cfssl gencert -initca ./k8s-core/docs/etcd/ca-csr.json | cfssljson -bare ./k8s-core/docs/etcd/env/ca

# all of the addresses (and/or DNS names) that could be used by clients or peers
node1=
node2=
node3=
node_common=
# example:
node1=k8s1-etcd1.k8s.lan
node2=k8s1-etcd2.k8s.lan
node3=k8s1-etcd3.k8s.lan
# node_common=k8s1-etcd-lb.k8s.lan

 cat << EOF > ./k8s-core/docs/etcd/env/etcd-csr.json
{
  "CN": "etcd",
  "hosts": [
    "localhost",
    "127.0.0.1",
    "${node1}",
    "${node2}",
    "${node3}",
    "${node_common}"
  ],
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "O": "Kubernetes",
      "OU": "etcd"
    }
  ]
}
EOF

rm ./k8s-core/docs/etcd/env/etcd-peer* ./k8s-core/docs/etcd/env/etcd-client*

cfssl gencert \
  -ca ./k8s-core/docs/etcd/env/ca.pem \
  -ca-key ./k8s-core/docs/etcd/env/ca-key.pem \
  -config ./k8s-core/docs/etcd/ca-config.json \
  -profile=etcd \
  ./k8s-core/docs/etcd/env/etcd-csr.json \
  | cfssljson -bare ./k8s-core/docs/etcd/env/etcd-peer
cfssl gencert \
  -ca ./k8s-core/docs/etcd/env/ca.pem \
  -ca-key ./k8s-core/docs/etcd/env/ca-key.pem \
  -config ./k8s-core/docs/etcd/ca-config.json \
  -profile=etcd \
  ./k8s-core/docs/etcd/env/etcd-csr.json \
  | cfssljson -bare ./k8s-core/docs/etcd/env/etcd-client

```

References:
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://github.com/etcd-io/etcd/blob/main/hack/tls-setup/README.md

# Set up cluster config

```bash

# node addresses for peer connections
# addresses used in TLS setup must include these
node1=k8s1-etcd1.k8s.lan
node2=k8s1-etcd2.k8s.lan
node3=k8s1-etcd3.k8s.lan
client_port=2379
peers_port=2380
cluster_token=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)

cluster_nodes=
nodes="$node1 $node2 $node3"
for node in $nodes; do
do
  cluster_nodes=$cluster_nodes,$node=https://$node:$peers_port
done
cluster_nodes="${cluster_nodes:1}"

mkdir -p ./k8s-core/docs/etcd/env/
for node in $nodes; do
do
  cat << EOF > ./k8s-core/docs/etcd/env/$node.conf
NODE_ADDRESS=https://$node:$peers_port
NODE_NAME=$node
CLUSTER_NODES=$cluster_nodes
CLUSTER_TOKEN=$cluster_token
CLIENT_PORT=$client_port
PEERS_PORT=$peers_port
EOF
done

```

# Enable cluster

Copy certificates and configs to all nodes.
For example:

```bash

etcd_username=root
nodes="$node1 $node2 $node3"
for node in $nodes; do
  scp \
    ./k8s-core/docs/etcd/systemd-service.conf \
    $etcd_username@$node:/etc/systemd/system/etcd3.service
done
for node in $nodes; do
  ssh $etcd_username@$node mkdir -p /etc/etcd/pki/
  scp \
    ./k8s-core/docs/etcd/env/ca.pem \
    ./k8s-core/docs/etcd/env/etcd-peer.pem \
    ./k8s-core/docs/etcd/env/etcd-peer-key.pem \
    ./k8s-core/docs/etcd/env/etcd-client.pem \
    ./k8s-core/docs/etcd/env/etcd-client-key.pem \
    $etcd_username@$node:/etc/etcd/pki/
done
for node in $nodes; do
  scp \
    ./k8s-core/docs/etcd/env/$node.conf \
    $etcd_username@$node:/etc/etcd.conf
done
for node in $nodes; do
  ssh $etcd_username@$node systemctl daemon-reload
  ssh $etcd_username@$node systemctl enable etcd3
  ssh $etcd_username@$node systemctl restart etcd3
done

```

In case etcd doesn't start, look at logs:

```bash

journalctl -xeu etcd3.service
# if there are too many logs, delete old logs and restart etcd
sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s
systemctl restart etcd3

```

# Setup aliases

```bash

ETCD_VER=v3.5.13
wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"
tar zxf "etcd-${ETCD_VER}-linux-amd64.tar.gz"
sudo mv "etcd-${ETCD_VER}-linux-amd64"/etcdctl /usr/local/bin/
rm -rf etcd*

 cat << EOF > ~/.bashrc.d/etcd-aliases.sh
# you may want to add this to your bashrc
alias etcdctl_cluster="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:$client_port,https://$node2:$client_port,https://$node3:$client_port \
  --cacert=./k8s-core/docs/etcd/env/ca.pem \
  --cert=./k8s-core/docs/etcd/env/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/etcd-client-key.pem"

alias etcdctl_node1="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:$client_port \
  --cacert=./k8s-core/docs/etcd/env/ca.pem \
  --cert=./k8s-core/docs/etcd/env/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/etcd-client-key.pem"

alias etcdctl_node2="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node2:$client_port \
  --cacert=./k8s-core/docs/etcd/env/ca.pem \
  --cert=./k8s-core/docs/etcd/env/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/etcd-client-key.pem"

alias etcdctl_node3="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node3:$client_port \
  --cacert=./k8s-core/docs/etcd/env/ca.pem \
  --cert=./k8s-core/docs/etcd/env/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/etcd-client-key.pem"
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
  --endpoints=https://$node2:$client_port,https://$node3:$client_port \
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

etcdctl endpoint status --write-out=json | jq .
# check database size
etcdctl endpoint status --write-out=json | jq .[].Status.dbSize | numfmt --to=iec

# get current cluster revision
etcdctl endpoint status --write-out=json | jq .[].Status.header.revision
# substitute your revision
etcdctl compact 816183644

# defrag one node at a time
etcdctl_node1 defrag
etcdctl_node2 defrag
etcdctl_node3 defrag

```
