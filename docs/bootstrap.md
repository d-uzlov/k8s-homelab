
# Bootstrap

This repository was created to document a certain setup that I'm using.

This file describes what you need to look for and in which order
to re-create that setup.

# LAN

This setup expects that you have a LAN behind NAT
with a public (although possibly dynamic) IP address.

It is advised to also have a DNS server in LAN.
This repo does not have instructions on how to set up one yet.

This repo uses only ipv4 addresses.

You will need additional LAN setup for k8s services:
- Exclude several IPs from DHCP to allow k8s to manage them
- Set up NAT port-forwarding for k8s services (once they get assigned an IP in LAN)

# Node setup

This repo assumes that you have at least 3 nodes:
- NAS for shared storage
- k8s control plane node
- k8s worker node

I run all nodes as VMs in Proxmox, but you can use whatever you want.

All VMs use Debian. There should not be too many differences between distros,
but I don't have installation instructions for other distros, and I didn't test them.

References:
- [proxmox](./proxmox/proxmox-host.md)
- [nas](./zfs-nas.md)
- [k8s control plane](../k8s-core/docs/ansible/control-plane.md)
- [k8s nodes](../k8s-core/docs/ansible/node-kubelet.md)

# DNS

You need to have some kind of a public domain.

There are services that can provide you with a free domain.
I keep a list of services I checked here: [free-dns.md](ingress/cert-manager/free-dns.md)

# k8s setup

- Install k8s
- - [k8s control plane](../k8s-core/docs/ansible/control-plane.md)
- - [k8s nodes](../k8s-core/docs/ansible/node-kubelet.md)
- Install CNI. For example:
- - [cilium](../network/cilium/readme.md) (recommended)
- - [calico](../network/calico/readme.md)
- Install [kubelet-csr-approver](../k8s-core/kubelet-csr-approver/readme.md)
- - This is required because we enabled proper certificates
- - `kubectl logs` command will not work until kubelet CSRs are approved.
- - - You can approve CSRs manually if you are having issues with the automatic approval
- [optional] Install other important deployments
- - [metrics-server](../k8s-core/metrics-server/readme.md)
- - [open-kruise](../k8s-core/open-kruise/readme.md)
- - [cgroup-burst controller](../k8s-core/cgroup-burst/readme.md)
- - [kyverno](../k8s-core/kyverno/readme.md)
- - [pod-name-webhook](../k8s-core/pod-name-webhook/readme.md)
- Install load balancer controller (pick only one). For example:
- - [kube-vip](../network/kube-vip-load-balancer/readme.md) (recommended)
- - [metalLB](../network/metallb/readme.md)
- - [cilium](../network/cilium/readme.md)
- - Test that load balancer services work: [example](../test/ingress/readme.md)
- Install [Gateway API](../ingress/gateway-api/readme.md)
- - Test that ingress works: [example](../test/ingress/readme.md)
- Set up public certificates
- - Install [cert-manager](../ingress/cert-manager/readme.md)
- - Option: use [HTTP01 challenge](../ingress/cert-manager/letsencrypt/readme.md) for certificates
- - - This should work universally, as long as your ingress can be accessed from the internet
- - Option: use DNS01 challenge for certificates:
- - - This allows you to create wildcard certificates
- - - [acme-dns](../ingress/cert-manager/acme-dns/readme.md) (work with any services that have CNAME support)
- - - [DuckDNS](../ingress/cert-manager/duckdns/readme.md)
- Connect cluster to some storage location
- - [democratic-csi](../storage/democratic-csi-generic/proxy/readme.md)
- Install other important deployments:
- - [prometheus-operator](../metrics/prometheus-operator/readme.md)
- - [prometheus](../metrics/prometheus/readme.md)
- - Look at all folders in `/metrics`
- - [CNPG (postgres)](../storage/postgres-cnpg/readme.md)
- - [dragonfly (redis)](../storage/redis-dragonfly/readme.md)

This mostly sums up all the infrastructure setup for k8s.

With this ready you can now deploy useful apps into the cluster.

Look around in the repo to see existing deployments.
