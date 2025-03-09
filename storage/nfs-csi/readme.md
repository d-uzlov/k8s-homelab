
# NFS CSI

This is s CSI plugin that can connect pods to remote NFS server.

References:
- https://github.com/kubernetes-csi/csi-driver-nfs

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts/
helm repo update csi-driver-nfs
helm search repo csi-driver-nfs/csi-driver-nfs --versions --devel | head
helm show values csi-driver-nfs/csi-driver-nfs --version v4.7.0 > ./storage/nfs-csi/default-values.yaml
```

```bash
helm template \
  csi-nfs \
  csi-driver-nfs/csi-driver-nfs \
  --version v4.7.0 \
  --values ./storage/nfs-csi/values.yaml \
  --namespace pv-nfs \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' \
  > ./storage/nfs-csi/nfs-csi.gen.yaml
```

# Deploy

```bash
kl create ns pv-nfs
kl label ns pv-nfs pod-security.kubernetes.io/enforce=privileged

kl -n pv-nfs apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-nfs apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/nfs-csi/
kl -n pv-nfs get pod -o wide
```

Don't forget to enable NFSv4 protocol on the server side.

# Cleanup

```bash
kl delete -k ./storage/nfs-csi/
kl delete ns pv-nfs
```

# Create storage classes

You need to create storage classes with proper settings to connect to your NFS server.

References:
- [bulk](./storage-classes/bulk/readme.md)
- [bulk-persist](./storage-classes/bulk-persist/readme.md)
- [fast](./storage-classes/fast/readme.md)
- [nfs-folder](./storage-classes/fast/readme.md)
- [shared](./storage-classes/shared/readme.md)

# Cache

Optionally you can enable fs-cache plugin for NFS, to cache often-used files on the node.
