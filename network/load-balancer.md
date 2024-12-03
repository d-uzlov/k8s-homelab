
# Load Balancer

# K8s documentation

https://kubernetes.io/docs/tutorials/services/source-ip/

# Comparison: MetalLB vs PureLB vs OpenALB

Useful overview:

Comparing Open Source k8s Load Balancers:
https://medium.com/thermokline/comparing-k8s-load-balancers-2f5c76ea8f31

# Good overview

The Kubernetes Networking Guide > Services > LoadBalancer
https://www.tkng.io/services/loadbalancer/

List of existing software L4 load balancers:
- MetalLB
    One of the most mature projects today.
    Supports both ARP and BGP modes via custom userspace implementations.
- OpenELB
    Developed as a part of a wider project called Kubesphere.
    Supports both ARP and BGP modes, with BGP implementation built on top of GoBGP. Configured via CRDs.
- Kube-vip
    Started as a solution for Kubernetes control plane high availability
    and got extended to function as a LoadBalancer controller.
    Supports both L2 and GoBGP-based L3 modes. Can be configured via flags, environment variables and ConfigMaps.
- PureLB
    Fork of metalLB with reworked ARP and BGP implementations. Uses BIRD for BGP and can be configured via CRDs.
- Klipper
    An integrated LB controller for K3S clusters. Exposes LoadBalancer Services as hostPorts on all cluster Nodes.
- Akrobateo
    Extends the idea borrowed from klipper to work on any general-purpose Kubernetes Node (not just K3S). Like klipper, it doesn’t use any extra protocol and simply relies on the fact that Node IPs are reachable from the rest of the network. The project is no longer active.

Existing load-balancer appliances from incumbent vendors
like F5 can be integrated with on-prem clusters
allowing for the same appliance instance to be re-used for multiple purposes.
https://cloud.google.com/architecture/partners/installing-f5-big-ip-adc-for-gke-on-prem?hl=en

## MetalLB

https://metallb.universe.tf

Has 2 modes: ARP and BGP.

https://metallb.universe.tf/configuration/_advanced_l2_configuration/
> In L2 mode, only one node is elected to announce the IP from.

https://metallb.universe.tf/usage/#layer2
> Pods that aren’t on the current leader node receive no traffic,
> they are just there as replicas in case a failover is needed.

`externalTrafficPolicy: local` will break things.

https://metallb.universe.tf/usage/#bgp
> With the Local traffic policy, nodes will only attract traffic
> if they are running one or more of the service’s pods locally

`externalTrafficPolicy: local` should work fine with BGP.

MetalLB can be used with Calico in BGP mode:
https://metallb.universe.tf/configuration/calico/

## PureLB

PureLB has 2 types of addresses: Local and Virtual.
Local are the ones that match LAN subnet. Virtual are all that don't.

https://purelb.gitlab.io/docs/how_it_works/localint/
> If a service using a pool with local addresses is configured
> for ExternalTrafficPolicy: Local, PureLB will reset it to Cluster.

Virtual addresses work as expected, but they require some external router software.

One of the suggested solutions is Calico integration:
https://purelb.gitlab.io/docs/cni/calico/

## OpenELB

https://openelb.io

Seems to be a Chinese software.

Documentation doesn't say anything about externalTrafficPolicy.

## kube-vip

https://kube-vip.io/docs/modes/arp/
> leaderElection per service
> In this mode kube-vip will perform an election every time a new Kubernetes service is created
> allowing service addresses to be spread across all nodes where a kube-vip pod is running.

https://kube-vip.io/docs/usage/kubernetes-services/#external-traffic-policy-kube-vip-v050
> In kube-vip a service can be created with the local traffic policy,
> if the enableServicesElection has been enabled.
> This is because when this service is created kube-vip
> will only allow nodes that have a local pod instance running to participate in the leaderElection.

https://kube-vip.io/docs/usage/kubernetes-services/#using-upnp-to-expose-a-service-to-the-outside-world
> With kube-vip > 0.2.1, it is possible to expose a Service of type LoadBalancer
> on a specific port to the Internet by using UPnP (on a supported gateway).

## Cilium

Cilium apparently supports source IP preservation using a feature called Direct Server Return:
- https://cilium.io/blog/2020/02/18/cilium-17/#kubeproxy-removal
- https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#direct-server-return-dsr

It can disable SNAT even for `externalTrafficPolicy: Cluster`.

However, it requires special network setup:
> DSR currently requires Cilium to be deployed in Native-Routing,
> i.e. it will not work in either tunneling mode.

Seems like currently it has built-in ability to advertise BGP routes
but doesn't support `externalTrafficPolicy: Local`:
https://github.com/cilium/cilium/issues/23035

## Calico

While Calico does not manage LoadBalancer services,
it has BGP more which can be used to advertise services
managed by other LoadBalancer controllers.

https://docs.tigera.io/calico/latest/networking/configuring/advertise-service-ips

In eBPF mode disables SNAT even for `externalTrafficPolicy: Cluster`,
and apparently it works fine even in tunneling mode.

# LoxiLB

References:
- https://www.loxilb.io/

Seems to be a new software load-balancer, as of 2024.

Uses eBPF, designed for high speed networking.
Prefers to be deployed separately from workloads, and transfer traffic to other nodes.

Also, apparently eBPF requires exclusive access to a cluster. So you can't use loxilb with cilium, for example.
But you can create a separate node for loxilb, and redirect traffic to cilium cluster.
