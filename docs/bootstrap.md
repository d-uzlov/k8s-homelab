
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
- Truenas
- k8s control plane node
- k8s worker node

Truenas here is used both as a local NAS and as a storage for k8s.

You can use virtual machines for nodes.
Make sure that your host supports both standard virtualization and IOMMU.

For VM host you can use Proxmox VE, aka pve.

For truenas it is advised to use controller passthrough,
so make sure that your host has at least 2 controllers.
For example, you can pass through SATA controller
while using NVMe for the host storage.

This repo assumes that you use Debian for k8s nodes.
You will need to search for alternative kubeadm installation commands
if you use a different distro,
or even use an alternative k8s provider, like k3s, microk8s, kops, etc.

References:
- [proxmox](./proxmox/proxmox-host.md)
- [truenas](./truenas.md)
- [k8s](./k8s/kubeadm-1-node-prep.md)

# DNS

Register at [DuckDNS](../ingress/cert-manager/duckdns/readme.md).

DuckDNS is a free Dynamic DNS service,
so you can use it even if you don't have a static IP.

If your IP is static you can simply skip setting up an IP updater.

# k8s setup

- [optional] Make sure that `hostname --fqdn` resolves to node IP
- [optional] Make sure that `hostname --fqdn` follows the same pattern on all nodes, for consistency
- Install k8s
- - This repo describes how to do it using [kubeadm](./k8s/kubeadm-install.md)
- - [optional] If you use proxmox, you can use VM templates: install k8s once, convert VM to template, clone it to create more nodes
- - - [Template setup](./proxmox.md#templates)
- - It is recommended to setup one separate master node and join at least one worker node
- Setup k8s:
- - [setup](./k8s/kubeadm-setup.md)
- - [maintenance](./k8s/kubeadm-maintenance.md)
- Install CNI. For example:
- - [cilium](../network/cilium/readme.md) (recommended)
- - [calico](../network/calico/readme.md)
- Install [kubelet-csr-approver](../metrics/kubelet-csr-approver/readme.md)
- - This is required because we enabled proper certificates
- - `kubectl logs` command will not work until kubelet CSRs are approved.
- - - You can approve CSRs manually if you are having issues with the automatic approval
- [optional] Enable metrics
- - Install [metrics-server](../metrics/metrics-server/readme.md)
- Install load balancer controller. For example:
- - [metallb](../network/metallb/readme.md) (recommended)
- - [kube-vip](../network/kube-vip-load-balancer/readme.md)
- - [cilium](../network/cilium/readme.md)
- - Test that load balancer services work: [example](../test/ingress/readme.md)
- Install ingress controller
- - [nginx](../ingress/nginx/readme.md)
- - Test that ingress works: [example](../test/ingress/readme.md)
- Set up public certificates
- - Install [cert-manager](../ingress/cert-manager/readme.md)
- - Option: use [HTTP01 challenge](../ingress/cert-manager/letsencrypt/readme.md) for certificates
- - - This should work universally, as long as your ingress can be accessed from the internet
- - Option: use DNS01 challenge for certificates:
- - - This allows you to create wildcard certificates
- - - [DuckDNS](../ingress/cert-manager/duckdns/readme.md)
- Connect cluster to some storage location
- - [List of available options](../storage/readme.md#storage-classes)

This mostly sums up all the infrastructure setup for k8s.

With this ready you can now deploy useful apps into the cluster.
