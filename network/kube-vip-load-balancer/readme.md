
# kube-vip

This is a load balancer for both control plane and services in the cluster.

Version `v0.6.0` seems to be broken.
It has some issues with k8s API,
which causes it to release all virtual IPs and never re-acquire them.

References:
- https://github.com/kube-vip/kube-vip

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
    > ./network/kube-vip-load-balancer/daemonset.gen.yaml
```

```bash
cat <<EOF > ./network/kube-vip-load-balancer/cm/env/ccm.env
# Local init
# Define CIDR or rande of IPs that LoadBalancer services are allowed to use
cidr-global=10.0.2.0/24
# alternatively you can use range instead of cidr
# range-global=
EOF

kl create ns kube-vip
kl apply -k ./network/kube-vip-load-balancer/cm
kl apply -k ./network/kube-vip-load-balancer
```

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
