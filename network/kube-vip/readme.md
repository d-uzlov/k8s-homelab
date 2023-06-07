
# kube-vip

This is a load balancer for both control plane and services in the cluster.



# Generate deployment

```bash
VIP=10.0.0.11
INTERFACE=ens18
KVVERSION=v0.6.0

docker run \
    --network host \
    --rm ghcr.io/kube-vip/kube-vip:$KVVERSION \
    manifest \
    pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    > ./network/kube-vip/static-pods.yaml
```

# Deploy

```bash
kl create ns kube-vip
kl apply -k ./network/kube-vip
```

# Deploy static pods

```bash
sudo mkdir -p /etc/kubernetes/manifests/
sudo nano /etc/kubernetes/manifests/kube-vip.yaml
```

