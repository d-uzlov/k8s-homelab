
# Democratic-CSI

Democratic-CSI is a universal CSI plugin for k8s.

In this repo there are several configs for connecting NFS and iSCSI to cluster.

Democratic-CSI requires you to create a separate controller for each storage location/type combo.

All deployments here assume that you are using Truenas Scale for storage.
Democratic-CSI supports other storage providers but there are no configs for them here.

# Configs

- [nfs bulk](./nfs/bulk/readme.md)
- [nfs fast](./nfs/fast/readme.md)
