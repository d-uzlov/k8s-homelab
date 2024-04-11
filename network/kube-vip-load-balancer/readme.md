
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
  docker.io/daniluzlov/k8s-snippets:kube-vip-0.7.2-nodename2 \
  manifest \
  daemonset \
  --log 5 \
  --inCluster \
  --services \
  --arp \
  --servicesElection \
  --prometheusHTTPServer :2113 \
  | sed -e '/creationTimestamp/d' \
  -e "s|image: .*|image: docker.io/daniluzlov/k8s-snippets:kube-vip-0.7.2-nodename3|" \
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

kl apply -k ./network/kube-vip-load-balancer/
kl apply -k ./network/kube-vip-load-balancer/ip-pool-config

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

# DHCP and UPnP

Kube-vip supports allocating IPs for LoadBalancer services from DHCP server.

It can also manage port-forwarding via UPnP.

To do this you need to assign a special IP `0.0.0.0` to the service.

References:
- https://kube-vip.io/docs/usage/kubernetes-services/#using-dhcp-for-load-balancers-experimental-kube-vip-v021
- https://kube-vip.io/docs/usage/kubernetes-services/#using-upnp-to-expose-a-service-to-the-outside-world
