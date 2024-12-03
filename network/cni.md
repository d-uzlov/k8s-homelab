
# CNI

By default Kubernetes doesn't have any internal network.
Pods won't even start.

CNI, Container Network Interface, solves this, by providing virtual network to containers.

CNIs are all-in-one solutions,
by choosing a CNI you choose a lot of different settings.

There are a lot of CNIs to choose from.

For example:
- Flannel
- Calico
- Cilium
- Antrea

# Flannel

Built-in CNI in some k8s distributions.

Often described as a simple CNI without many functions.

# Calico

One of the popular choices.
Has a lot of options, though I use only a small subset.

Has eBPF mode.
In eBPF mode supports Source IP Preservation
and Direct Service Return.

# Cilium

Apparently also popular.

Main gimmick is that it always uses eBPF.
Also has built-in monitoring solution.

But maybe it's not very good: https://www.reddit.com/r/kubernetes/comments/11pgmsa/comment/jc2b7kv/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

Seems to support Source IP Preservation
and Direct Service Return.

# Antrea

Main gimmick is the ability to set egress IP based on namespace or labels.
