
# kubeadm setup

This file describes how to create k8s cluster when you already have ready-to-use nodes.

# Prerequisites

1. Each master node must have a static IP.

If you want to change master node IP, join a second node and remove the first one.

Worker nodes seems to work fine with dynamic IPs.

Etcd IP is baked into many things. It can be solved by using external etcd.

Master nodes are registered with IP (aka `advertise-address`).
When this IP changes, it's as if you join a different node with the same name,
which causes collisions, and some things break.

It's possible to re-program the node to update the certificate to include new IP,
and change apiserver pod to work with whatever IP it has,
but kubelet has a lot of errors in its logs, and node CSRs don't work properly,
and there are likely other issues.

References:
- https://github.com/kubernetes/kubeadm/issues/338

2. Create a stable DNS address for control plane endpoint.

If you only want 1 master node, it can point to this node.
If you have several master nodes, it needs to point to some common virtual IP, or a load balancer.
If for now you have 1 but later you'll want to add more, you can just re-configure this DNS address.

This address must be available before you create the cluster, or kubelet will fail to start.

For example: [kube-vip for control plane](../../network/kube-vip-control-plane/readme.md).

3. Local setup

- `kubectl` installed
- [optional] Passwordless sudo on the nodes

# Set up cluster config

```bash
# add key or user if needed
cp_node1=
# you can print the default config
# this is just for reference, you don't really need it
ssh $cp_node1 sudo kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration > ./k8s-core/docsenv/kconf-default.yaml
echo --- >> ./k8s-core/docsenv/kconf-default.yaml
ssh $cp_node1 sudo kubeadm config print join-defaults >> ./k8s-core/docsenv/kconf-default.yaml

control_plane_endpoint=cp.k8s.lan
serverTLSBootstrap=true
# one of: local, external
etcd_type=external
# only relevant when using external etcd
etcd_endpoint1=https://k8s1-etcd1.k8s.lan:2379
etcd_endpoint2=https://k8s1-etcd2.k8s.lan:2379
etcd_endpoint3=https://k8s1-etcd3.k8s.lan:2379
sed -e "s/REPLACE_ME_CONTROL_PLANE_ENDPOINT/$control_plane_endpoint/" \
  -e "s/REPLACE_ME_SERVER_TLS_BOOTSTRAP/$serverTLSBootstrap/" \
  -e "/remove when using $etcd_type etcd/,/remove when using $etcd_type etcd/d" \
  -e "s|REPLACE_ME_ETCD_ENDPOINT1|$etcd_endpoint1|" \
  -e "s|REPLACE_ME_ETCD_ENDPOINT2|$etcd_endpoint2|" \
  -e "s|REPLACE_ME_ETCD_ENDPOINT3|$etcd_endpoint3|" \
  ./k8s-core/docskubeadm-config/init.yaml \
  ./k8s-core/docskubeadm-config/cluster.yaml \
  ./k8s-core/docskubeadm-config/kubelet.yaml \
  ./k8s-core/docskubeadm-config/kube-proxy.yaml \
  > ./k8s-core/docsenv/kconf-$control_plane_endpoint.yaml
# review kconf.yaml before copying it to make sure everything is OK
scp ./k8s-core/docsenv/kconf-$control_plane_endpoint.yaml $cp_node1:kconf.yaml

# Later you will be able to configure auth without changes in the apiserver config.
# apiserver watches changes in the auth-config file.
ssh $cp_node1 sudo mkdir -p /etc/k8s-auth/
ssh $cp_node1 sudo tee '>' /dev/null /etc/k8s-auth/auth-config.yaml < ./k8s-core/docsauth-config-init.yaml

```

# Setup cluster

```bash
cp_node1=
ssh $cp_node1 kubeadm config validate --config ./kconf.yaml

# if you are using external etcd, copy etcd certs
ssh $cp_node1 sudo mkdir -p /etc/etcd/pki/
ssh $cp_node1 sudo tee '>' /dev/null /etc/etcd/pki/ca.pem              < ./k8s-core/docsetcd/env/ca.pem
ssh $cp_node1 sudo tee '>' /dev/null /etc/etcd/pki/etcd-client.pem     < ./k8s-core/docsetcd/env/etcd-client.pem
ssh $cp_node1 sudo tee '>' /dev/null /etc/etcd/pki/etcd-client-key.pem < ./k8s-core/docsetcd/env/etcd-client-key.pem

scp -r ./k8s-core/docspatches $cp_node1:./patches

# if using kube-vip for control plane, you should switch to its commands at this point

# init remotely
ssh $cp_node1 sudo kubeadm init \
  --config ./kconf.yaml \
  --node-name '"$(hostname --fqdn)"' \
  --skip-phases show-join-command

# or locally
sudo kubeadm init \
  --config ./kconf.yaml \
  --node-name "$(hostname --fqdn)" \
  --skip-phases show-join-command

# fetch admin kubeconfig
ssh $cp_node1 sudo cat /etc/kubernetes/admin.conf > ./_env/"$control_plane_endpoint".yaml

# check cluster state
kubectl --kubeconfig ./_env/"$control_plane_endpoint".yaml -n kube-system get node -o wide
kubectl --kubeconfig ./_env/"$control_plane_endpoint".yaml -n kube-system get pod -A -o wide
kubectl --kubeconfig ./_env/"$control_plane_endpoint".yaml -n kube-system get csr

# if you enabled serverTLSBootstrap, you need to manually approve CSRs
# change to your CSR names
kubectl --kubeconfig ./_env/"$control_plane_endpoint".yaml -n kube-system certificate approve csr-8dhw5 csr-wp6k6 csr-wqd9s csr-zjn49
kubectl --kubeconfig ./_env/"$control_plane_endpoint".yaml -n kube-system logs -l component=kube-apiserver
```

# Join additional nodes

Show command to join:

```bash
# worker join (doesn't have any special prerequisites)
ssh $cp_node1 bash -s - < ./k8s-core/docsprint-join.sh worker

# master join:
# - requires kconf.yaml on the node generating the command
scp ./k8s-core/docsenv/kconf-$control_plane_endpoint.yaml $cp_node1:kconf.yaml
ssh $cp_node1 bash -s - < ./k8s-core/docsprint-join.sh master
# - requires patches directory to be present on the node joining the cluster
scp -r ./k8s-core/docspatches $cp_node1:./patches
```

Run printed command on additional nodes to join the cluster.
Token in printed commands will expire in 2 hours.
Until then you can join however many nodes you want.

For master nodes remember:
- They should have static IP
- When using local etcd, deploy 1, 3, or 5 master nodes for proper HA
- With external etcd it's fine to have 2 master nodes, for example
- Don't forget about kube-vip if you are using it

# Next actions

- Install CNI
- `serverTLSBootstrap`: [CSR approver](../../metrics/kubelet-csr-approver/readme.md)
