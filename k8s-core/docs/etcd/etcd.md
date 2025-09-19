
# etcd cluster

This file provides instructions to create an etcd cluster.
The main intent is to use it as an external etcd for k8s.

References:
- https://etcd.io/docs/v3.6/op-guide/clustering/
- https://github.com/etcd-io/etcd/tree/main/hack/tls-setup
- https://etcd.io/docs/v3.6/install/
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://docs.ondat.io/docs/prerequisites/etcd/etcd-outside-the-cluster/
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://github.com/etcd-io/etcd/blob/main/hack/tls-setup/README.md

# prerequisites

- 1 or 3 VMs or LXC containers dedicated to etcd
- - 1 is no redundancy, 2 is still no redundancy, with 3 instances one may fail without affecting clients
- L3 connectivity between hosts, L3 should be enough
- DNS records for all etcd hosts

```bash

# install cfssl
wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64
wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64

chmod +x ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64
chmod +x ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64
sudo cp ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64 /usr/local/bin/cfssl
sudo cp ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64 /usr/local/bin/cfssljson

```

# generate ca cert

```bash

# cluster and node names must correspond to values in ansible inventory
etcd_cluster_name=

mkdir -p ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/

cfssl gencert -initca ./k8s-core/docs/etcd/ca-csr.json | cfssljson -bare ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/ca

```

# ansible inventory

You need to add your etcd nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
etcd-1:
  ansible_host: etcd-1.k8s.lan
  ansible_python_interpreter: auto_silent
  # cluster name is used for local directory structure
  etcd_cluster_name: my-etcd-cluster
  etcd_cluster_token: qwe123
  etcd_node_name: etcd-1.k8s.lan
  etcd_node_peer_address: https://etcd-1.k8s.lan:2380
  # node1_name=node1_address,node2_name=...
  etcd_init_cluster_nodes: etcd-1.k8s.lan=https://etcd-1.k8s.lan:2380,etcd-2.k8s.lan=https://etcd-2.k8s.lan:2380,etcd-3.k8s.lan=https://etcd-3.k8s.lan:2380
```

You can generate `etcd_cluster_token` like this:

```bash
echo $(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
```

# install

This playbook is suitable for initial cluster setup
or for cluster updates.

If you have a failed node and want to replace it
you will need to run additional manual commands.
See [disaster-recovery](./etcdctl.md#disaster-recovery).

```bash

ansible-inventory --graph etcd

# you are encouraged to run the playbook one node at a time,
ansible-playbook ./k8s-core/docs/etcd/etcd-playbook.yaml --limit k8s1-etcd1.k8s.lan

# unless you are initializing a new cluster
ansible-playbook ./k8s-core/docs/etcd/etcd-playbook.yaml

```

# create client certificate

```bash

etcd_cluster_name=b2788
etcd_client_name=invalid

 cat << EOF > ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/client-$etcd_client_name.json
{
  "CN": "$etcd_client_name",
  "key": {
    "algo": "ecdsa",
    "size": 384
  },
  "hosts": [
    "$etcd_client_name"
  ]
}
EOF

cfssl gencert \
  -ca ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/ca.pem \
  -ca-key ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/ca-key.pem \
  -config ./k8s-core/docs/etcd/ca-config.json \
  -profile=etcd \
  ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/client-$etcd_client_name.json \
  | cfssljson -bare ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/client-$etcd_client_name

```
