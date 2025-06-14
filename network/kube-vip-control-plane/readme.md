
# kube-vip

Kube-vip allow you to create a virtual IP for HA control plane consisting of several nodes.

It works when you have only one control plane node, but it isn't as useful in such setups.

References:
- https://github.com/kube-vip/kube-vip
- https://kube-vip.io

# Generate template

```bash

# VIP_STUB and INTERFACE_STUB will be replaced later, using sed
docker run \
  --network host \
  docker.io/daniluzlov/k8s-snippets:kube-vip-0.7.2-nodename2 \
  manifest \
  pod \
  --address VIP_STUB \
  --interface INTERFACE_STUB \
  --controlplane \
  --arp \
  | sed -e '\|creationTimestamp|d' \
  -e "s|image: .*|image: docker.io/daniluzlov/k8s-snippets:kube-vip-0.7.2-nodename3|" \
  > ./network/kube-vip-control-plane/static-pod-template.gen.yaml

```

# Deploy static pods

Run this for the first master node just before `kubeadm init`.
Run this for other master nodes after `kubeadm join`.
Don't run this for worker nodes.

```bash
cp_node1=m2.k8s.lan
# any free IP in lan
VIP=10.3.0.255
# corresponding interface of the node, can be different on different nodes
INTERFACE=eth1

mkdir -p ./network/kube-vip-control-plane/env/
sed -e "s/VIP_STUB/'$VIP'/" \
  -e "s/INTERFACE_STUB/$INTERFACE/" \
  ./network/kube-vip-control-plane/static-pod-template.gen.yaml \
  > ./network/kube-vip-control-plane/env/$cp_node1.yaml
ssh "$cp_node1" sudo mkdir -p /etc/kubernetes/manifests/

ssh "$cp_node1" sudo tee /etc/kubernetes/manifests/kube-vip.yaml '>' /dev/null < ./network/kube-vip-control-plane/env/$cp_node1.yaml

# for the first master node change the config before deploying k8s
# other nodes don't need this
# see reasoning here: https://github.com/kube-vip/kube-vip/issues/684
ssh $cp_node1 sudo sed -i '"s#path: /etc/kubernetes/admin.conf#path: /etc/kubernetes/super-admin.conf#"' /etc/kubernetes/manifests/kube-vip.yaml
# change it back after kubeadm init has finished
ssh $cp_node1 sudo sed -i '"s#path: /etc/kubernetes/super-admin.conf#path: /etc/kubernetes/admin.conf#"' /etc/kubernetes/manifests/kube-vip.yaml
```
