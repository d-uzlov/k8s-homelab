
# kubeadm setup

This file describes how to create k8s cluster when you already have ready-to-use nodes.

# Prerequisites

1. Each master node must have a static IP. Many things will break if IP changes.

When a master node joins the cluster, it registers with its current `advertise-address`,
which is currently enforced to be direct IP. Also, this IP is baked into node certificate.
Even though you can re-configure kube-apiserver locally,
it will have troubles connecting to the rest of the cluster, or to etcd.

If you want to change master node IP, join a second node and remove the first one.

Worker nodes seems to work fine with dynamic IPs.

References:
- https://github.com/kubernetes/kubeadm/issues/338

2. DNS address for control plane endpoint.

If you only want 1 master node, it can point to this node.
If you have several master nodes, it needs to point to some common virtual IP, or a load balancer.
If for now you have 1 but later you'll want to add more, you can just configure this DNS address.

This address must be available before you create the cluster, or kubelet will fail to start.

For example: [kube-vip for control plane](../../network/kube-vip-control-plane/readme.md).

# Set up cluster config

```bash
cp_node1=m1.k8s.lan
# you can print the default config just for reference
ssh "$cp_node1" sudo kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration > ./docs/k8s/kconf-default.yaml
ssh "$cp_node1" sudo kubeadm config print join-defaults >> ./docs/k8s/kconf-default.yaml

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
  ./docs/k8s/kconf.yaml > ./docs/k8s/env/kconf.yaml
# review kconf.yaml before copying it to make sure everything is OK
scp ./docs/k8s/env/kconf.yaml $cp_node1:kconf.yaml
```

# Setup cluster

```bash
cp_node1=m1.k8s.lan
ssh $cp_node1 kubeadm config validate --config ./kconf.yaml

# if you are using external etcd, copy etcd certs
ssh $cp_node1 sudo mkdir -p /etc/etcd/pki/
ssh $cp_node1 sudo tee /etc/etcd/pki/ca.pem '>' /dev/null < ./docs/k8s/etcd/env/ca.pem
ssh $cp_node1 sudo tee /etc/etcd/pki/etcd-client.pem '>' /dev/null < ./docs/k8s/etcd/env/etcd-client.pem
ssh $cp_node1 sudo tee /etc/etcd/pki/etcd-client-key.pem '>' /dev/null < ./docs/k8s/etcd/env/etcd-client-key.pem

# if using kube-vip for control plane, you should switch to its commands at this point
# also, run this after copying the kube-vip manifest
# this is only required for the first node of the cluster
ssh $cp_node1 sudo sed -i '"s#path: /etc/kubernetes/admin.conf#path: /etc/kubernetes/super-admin.conf#"' /etc/kubernetes/manifests/kube-vip.yaml
# see details here: https://github.com/kube-vip/kube-vip/issues/684

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

# when using kube-vip for control plane, also run this, only on the first node of the cluster
ssh $cp_node1 sudo sed -i '"s#path: /etc/kubernetes/super-admin.conf#path: /etc/kubernetes/admin.conf#"' /etc/kubernetes/manifests/kube-vip.yaml

# check cluster state in place
ssh $cp_node1 sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get node -o wide
ssh $cp_node1 sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get pod -A -o wide
ssh $cp_node1 sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get csr
# change to your CSR names
ssh $cp_node1 sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system certificate approve csr-8dhw5 csr-wp6k6 csr-wqd9s csr-zjn49
ssh $cp_node1 sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system logs -l component=kube-apiserver

# fetch admin kubeconfig
ssh $cp_node1 sudo cat /etc/kubernetes/admin.conf > ./_env/"$control_plane_endpoint".yaml
```

# Join additional nodes

Show command to join:

```bash
# worker join can be generated on any master node
ssh $cp_node1 bash -s - < ./docs/k8s/print-join.sh worker
# master join requires kconf.yaml to be presetn, copy it into the node if needed
ssh $cp_node1 bash -s - < ./docs/k8s/print-join.sh master
```

Run printed command on additional nodes to join the cluster.
Commands will expire in 2 hours. Until then you can join however many nodes you want.

For master nodes remember:
- They should have static IP
- When using local etcd, deploy 1, 3, or 5 master nodes for proper HA
- With external etcd it's fine to have 2 master nodes, for example
- Don't forget about kube-vip if you are using it

# Next actions

- Install CNI
- `serverTLSBootstrap`: [CSR approver](../../metrics/kubelet-csr-approver/readme.md)

# Remove node from cluster

First remove pods and the node itself using kubectl:

```bash
kl drain n100.k8s.lan --ignore-daemonsets --delete-emptydir-data
kl delete node n100.k8s.lan
```

Then ssh into the removed node and disable kubelet:

```bash
sudo kubeadm reset --force
sudo rm -rf /etc/cni/
sudo rm -rf /var/lib/kubelet/
sudo reboot
```

When using local etcd, master node removal requires additional configuration:
For example: https://paranoiaque.fr/en/2020/04/19/remove-master-node-from-ha-kubernetes/

# Kubelet logs

```bash
# it is advised to clear logs before kubelet restart, if you want to read them
# WARNING: this will delete all node logs, not only from kubelet
sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s
sudo systemctl restart kubelet

# show full logs
journalctl -x --unit kubelet
# show last 50 lines
journalctl -x -n 50 --unit kubelet
```
