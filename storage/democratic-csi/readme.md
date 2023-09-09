
# Democratic-CSI

Democratic-CSI is a universal CSI plugin for k8s.

In this repo there are several configs for connecting NFS and iSCSI to cluster.

Democratic-CSI requires you to create a separate controller for each storage location/type combo.

All deployments here assume that you are using Truenas Scale for storage.
Democratic-CSI supports other storage providers but there are no configs for them here.

# Guides

References:
- https://jonathangazeley.com/2021/01/05/using-truenas-to-provide-persistent-storage-for-kubernetes/
- https://github.com/fenio/k8s-truenas
- https://jonathangazeley.com/2023/02/01/kubernetes-homelab-part-3-off-cluster-storage/
