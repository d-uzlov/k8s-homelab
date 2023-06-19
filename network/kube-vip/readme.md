
# kube-vip

This is a load balancer for both control plane and services in the cluster.

Version `v0.6.0` seems to be broken.
It has some issues with k8s API,
which causes it to release all virtual IPs and never re-acquire them.

# Deploy daemon set for LoadBalancer services

In case you need to change any settings,
re-generate daemon set config:
```bash
docker run \
    --network host \
    --rm ghcr.io/kube-vip/kube-vip:v0.5.12 \
    manifest \
    daemonset \
    --inCluster \
    --services \
    --arp \
    --servicesElection \
    --prometheusHTTPServer :2113 \
    > ./network/kube-vip/daemonset.gen.yaml
```

```bash
# Local init
cat <<EOF > ./network/kube-vip/cm/env/ccm.env
# Define CIDR or rande of IPs that LoadBalancer services are allowed to use
cidr-global=10.0.3.0/24
# alternatively you can use range instead of cidr
# range-global=
EOF

kl create ns kube-vip
kl apply -k ./network/kube-vip/cm
kl apply -k ./network/kube-vip
```

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
    > ./network/kube-vip/static-pods.gen.yaml
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

# Lease settings

Kube-vip can restart due to improper lease settings.

It seems like settings from k8s works fine.

References:
- https://github.com/kube-vip/kube-vip/issues/282
- https://github.com/kubernetes/client-go/blob/v0.27.2/tools/leaderelection/leaderelection.go#L111

# DHCP and UPnP

Kube-vip supports allocating IPs for LoadBalancer services from DHCP server.

It can also manage port-forwarding via UPnP.

References:
- https://kube-vip.io/docs/usage/kubernetes-services/#using-dhcp-for-load-balancers-experimental-kube-vip-v021
- https://kube-vip.io/docs/usage/kubernetes-services/#using-upnp-to-expose-a-service-to-the-outside-world
