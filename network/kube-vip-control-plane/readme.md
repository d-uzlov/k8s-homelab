
# kube-vip

Kube-vip allow you to create a virtual IP for HA control plane consisting of several nodes.

It works when you have only one control plane node, but it isn't as useful in such setups.

References:
- https://github.com/kube-vip/kube-vip
- https://kube-vip.io

# Generate template

```bash
docker run \
  --network host \
  --rm ghcr.io/kube-vip/kube-vip:v0.7.2 \
  manifest \
  pod \
  --address REPLACE_ME_VIP \
  --interface REPLACE_ME_INTERFACE \
  --controlplane \
  --arp \
  | sed -e '\|creationTimestamp|d' \
  > ./network/kube-vip-control-plane/static-pod-template.gen.yaml
```

# Deploy static pods

Run this for the first master node just before `kubeadm init`.
Run this for other master nodes after `kubeadm join`.
Don't run this for worker nodes.

```bash
cp_node1=m1.k8s.lan
# any free IP in lan
VIP=10.3.0.255
# corresponding interface of the node
INTERFACE=eth1

mkdir -p ./network/kube-vip-control-plane/env/
sed -e "s/REPLACE_ME_VIP/'$VIP'/" \
  -e "s/REPLACE_ME_INTERFACE/$INTERFACE/" \
  ./network/kube-vip-control-plane/static-pod-template.gen.yaml \
  > ./network/kube-vip-control-plane/env/$cp_node1.yaml
ssh "$cp_node1" sudo mkdir -p /etc/kubernetes/manifests/
ssh "$cp_node1" sudo tee /etc/kubernetes/manifests/kube-vip.yaml '>' /dev/null < ./network/kube-vip-control-plane/env/$cp_node1.yaml
```
