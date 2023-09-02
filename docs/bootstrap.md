
# Bootstrap

This repository was created to document a certain setup that I'm using.

This file describes what you need to look for and in which order
to re-create that setup.

# LAN

This setup expects that you have a LAN behind NAT
with a public (although possibly dynamic) IP address.

It is advised to also have a DNS server in LAN.
This repo does not have instructions to set up one yet.

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
- [proxmox](./proxmox.md)
- [truenas](./truenas.md)
- [ubuntu](./ubuntu.md)
- [debian](./debian.md)

# DNS

Register at [DuckDNS](../ingress/cert-manager/duckdns/readme.md).

DuckDNS is a free Dynamic DNS service,
so you can use it even if you don't have a static IP.

If your IP is static you can simply skip setting up an IP updater.

# k8s setup

- [optional] Set up Debian template in Proxmox
- - [Template setup](./proxmox.md#templates)
- Install k8s
- - This repo describes how to do it using [kubeadm](./kubeadm.md)
- - If you use templates, you can install it once, convert VM to template, and clone it to create nodes
- - It is recommended to setup one separate master node and join at least one worker node
- Install CNI. For example:
- - [cilium](../network/cilium/readme.md) (recommended)
- - [calico](../network/calico/readme.md)
- [optional] Enable metrics
- - Make sure you enable k8s certificates generation during k8s installation
- - Install [kubelet-csr-approver](../metrics/kubelet-csr-approver/readme.md)
- - Install [metrics-server](../metrics/metrics-server/readme.md)
- - Note, that if you enable TLS certificate bootstrap,
`kubectl logs` command will not work until kubelet CSRs are approved.
- - - If there are any issues with CNI, you will have a hard time debugging it.
- - - It would be easier to re-deploy the cluster with automatic certificates,
make sure that CNI config is correct, and then re-deploy it again with manual certificates.
- - - Alternatively, you could approve CSRs manually.
- Install load balancer controller. For example:
- - [kube-vip](../network/kube-vip/readme.md) (recommended)
- - [metallb](../network/metallb/readme.md)
- Install ingress controller
- - [nginx](../ingress/nginx/readme.md)
- - Test that ingress works: [example](../test/ingress/readme.md)
- Set up public certificates
- - Install [cert-manager](../ingress/cert-manager/readme.md)
- - Test cert-manager using letsencrypt staging environment
- Connect storage to the cluster
- - Set up [nfs](../storage/nfs-csi/readme.md)
- - Set up [iscsi](../storage/democratic-csi/readme.md)

This mostly sums up all the infrastructure setup for k8s.

With this ready you can now deploy useful apps into the cluster.
