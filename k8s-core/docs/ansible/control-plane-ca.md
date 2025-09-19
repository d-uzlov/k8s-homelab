
# cluster CA

For this guide you need to have cluster CA in your local filesystem.

You can generate them from scratch if you are creating a new cluster.

When running kubeadm, each master node has a copy of cluster CA.

# create new CA

https://github.com/ghik/kubernetes-the-harder-way/blob/linux/docs/04_Bootstrapping_Kubernetes_Security.md

```bash

# cluster and node names must correspond to values in ansible inventory
k8s_cluster_name=

mkdir -p ./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/

cfssl gencert -initca ./k8s-core/docs/ansible/csr/ca-csr.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$k8s_cluster_name/ca/ca

```

Note that this CA file is like an admin key to the cluster.

You must keep it in a secure place.

# extract CA files from existing cluster node

```bash

k8s_cluster_name=

mkdir -p ./k8s-core/docs/ansible/env/cluster-$k8s_cluster_name/ca/

master_node=
ssh $master_node sudo cat /etc/kubernetes/pki/ca.crt > ./k8s-core/docs/ansible/env/cluster-$k8s_cluster_name/ca/ca.pem
ssh $master_node sudo cat /etc/kubernetes/pki/ca.key > ./k8s-core/docs/ansible/env/cluster-$k8s_cluster_name/ca/ca-key.pem

```
