
# cluster CA

For this guide you need to have cluster CA in your local filesystem.

You can generate them from scratch.

When running kubeadm, cluster CA files are kept in master node filesystem.
So you need to run kubeadm on the master to generate join link, for example.

You can extract cluster CA files from any master node.

# create new CA

https://github.com/ghik/kubernetes-the-harder-way/blob/linux/docs/04_Bootstrapping_Kubernetes_Security.md

# extract CA files from existing cluster node

```bash

cluster_name=trixie

mkdir -p ./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/

master_node=m1.k8s.lan
ssh $master_node sudo cat /etc/kubernetes/pki/ca.crt > ./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem
ssh $master_node sudo cat /etc/kubernetes/pki/ca.key > ./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem

```
