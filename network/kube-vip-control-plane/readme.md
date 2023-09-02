
# kube-vip

This is a load balancer for both control plane and services in the cluster.

Version `v0.6.0` seems to be broken.
It has some issues with k8s API,
which causes it to release all virtual IPs and never re-acquire them.

References:
- https://github.com/kube-vip/kube-vip

# Deploy static pods

Kube-vip allow you to create a virtual IP for HA control plane.

It works when you have only one control plane node, but it isn't as useful in such setups.

Static pods should not be deployed on worker nodes.

Generate config:
```bash
# any free IP in lan, or DNS name
VIP=10.0.0.11
docker run \
    --network host \
    --rm ghcr.io/kube-vip/kube-vip:v0.5.12 \
    manifest \
    pod \
    --address $VIP \
    --controlplane \
    --arp \
    --leaderElection \
    --leaseDuration 15 \
    --leaseRenewDuration 10 \
    --leaseRetry 2 \
    --prometheusHTTPServer :2112 \
    > ./network/kube-vip-control-plane/static-pods.gen.yaml
```

Before deploying first control plane node
copy [pod config](./static-pods.yaml) into manifests folder:
```bash
sudo mkdir -p /etc/kubernetes/manifests/

sudo nano /etc/kubernetes/manifests/kube-vip.yaml
```
Kube-vip documentation says that on other control plane nodes
static pods should be created after `kubeadm init`.
I didn't check it.
