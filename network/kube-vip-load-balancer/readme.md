
# kube-vip

This is a load balancer for both control plane and services in the cluster.

References:
- https://kube-vip.io
- https://github.com/kube-vip/kube-vip
- https://github.com/kube-vip/kube-vip-cloud-provider

# Create config

Required for major config changes or updates.

You don't need to do it if you are just deploying it.

```bash
docker run \
  --network host \
  --rm \
  ghcr.io/kube-vip/kube-vip:v0.8.0 \
  manifest \
  daemonset \
  --log 5 \
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
 cat << EOF > ./network/kube-vip-load-balancer/ccm/cm/env/ccm.env
cidr-global=10.0.2.0/24
range-global=
EOF
```

# Deploy

```bash
kl create ns kube-vip

kl apply -k ./network/kube-vip-load-balancer/
kl apply -k ./network/kube-vip-load-balancer/ip-pool-config/

kl -n kube-vip get pod -o wide
kl -n kube-vip logs ds/kube-vip-ds
```

# Cleanup

```bash
kl delete -k ./network/kube-vip-load-balancer/
kl delete -k ./network/kube-vip-load-balancer/ip-pool-config
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

# Lease delay

If you prefer that some nodes don't advertise IPs you can annotate
these nodes to add delay to service leader election.
Nodes with higher delay are less likely to get the lease,
and therefore less likely to advertise service IP.

This does not disable services on this node.
If this node is the only one that has local endpoints,
and service specifies `externalTrafficPolicy: Local`,
this node will still get the lease, and will advertise the load balancer address.

This is a custom patch to kube-vip, it is not available in the official images.

```bash
kl annotate node m1.k8s.lan --overwrite kube-vip.io/ElectionDelayMs=200

kl get node -o custom-columns='NAME:metadata.name,ELECTION DELAY:metadata.annotations.kube-vip\.io/ElectionDelayMs'
./logs.sh kube-vip kube-vip-ds | grep delay
```

# DHCP and UPnP

Kube-vip supports allocating IPs for LoadBalancer services from DHCP server.

It can also manage port-forwarding via UPnP.

To do this you need to assign a special IP `0.0.0.0` to the service.

References:
- https://kube-vip.io/docs/usage/kubernetes-services/#using-dhcp-for-load-balancers-experimental-kube-vip-v021
- https://kube-vip.io/docs/usage/kubernetes-services/#using-upnp-to-expose-a-service-to-the-outside-world
