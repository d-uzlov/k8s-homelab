
# kube-vip

This is a load balancer for both control plane and services in the cluster.

References:
- https://github.com/kube-vip/kube-vip

# Create config

Required for major config changes or updates.

You don't need to do it if you are just deploying it.

```bash
docker run \
  --network host \
  --rm \
  ghcr.io/kube-vip/kube-vip:v0.6.3 \
  manifest \
  daemonset \
  --inCluster \
  --services \
  --arp \
  --servicesElection \
  --prometheusHTTPServer :2113 \
  | sed -e '/creationTimestamp/d' \
  > ./network/kube-vip-load-balancer/daemonset.gen.yaml
```

# Set up your local environment

Define CIDR or range of IPs that LoadBalancer services are allowed to use:

```bash
mkdir -p ./network/kube-vip-load-balancer/ccm/cm/env/
cat <<EOF > ./network/kube-vip-load-balancer/ccm/cm/env/ccm.env
cidr-global=10.0.2.0/24
range-global=
EOF
```

# Deploy

```bash
kl create ns kube-vip

# main app
kl apply -k ./network/kube-vip-load-balancer/
# cloud controller manager, required to assign external IPs to services
kl apply -k ./network/kube-vip-load-balancer/ccm/
# configmap for ccm
kl apply -k ./network/kube-vip-load-balancer/ccm/cm/

kl -n kube-vip get pod -o wide
```

# Cleanup

```bash
kl delete -k ./network/kube-vip-load-balancer/
kl delete -k ./network/kube-vip-load-balancer/ccm/cm/
kl delete -k ./network/kube-vip-load-balancer/ccm/
kl delete ns kube-vip
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)

# Lease settings

Kube-vip can restart due to improper lease settings.

It seems like settings from k8s works fine.

References:
- https://github.com/kube-vip/kube-vip/issues/282
- https://github.com/kubernetes/client-go/blob/v0.27.2/tools/leaderelection/leaderelection.go#L111

# DHCP and UPnP

Kube-vip supports allocating IPs for LoadBalancer services from DHCP server.

It can also manage port-forwarding via UPnP.

To do this you need to assign a special IP `0.0.0.0` to the service.

References:
- https://kube-vip.io/docs/usage/kubernetes-services/#using-dhcp-for-load-balancers-experimental-kube-vip-v021
- https://kube-vip.io/docs/usage/kubernetes-services/#using-upnp-to-expose-a-service-to-the-outside-world
