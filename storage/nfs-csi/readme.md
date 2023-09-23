
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
helm show values csi-driver-nfs/csi-driver-nfs > ./storage/nfs-csi/default-values.yaml
```

```bash
helm template \
  csi-nfs \
  csi-driver-nfs/csi-driver-nfs \
  --version v4.4.0 \
  --values ./storage/nfs-csi/values.yaml \
  --namespace pv-nfs \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' \
  > ./storage/nfs-csi/nfs-csi.gen.yaml
```

# Deploy

```bash
kl create ns pv-nfs
kl apply -k ./storage/nfs-csi
kl -n pv-nfs get pod
```

Don't forget to enable NFSv4 protocol on the server side.

# Create storage classes

You need to create storage classes with proper settings to connect to your NFS server.

References:
- [storage-classes](./storage-classes/readme.md)

# Cache

Optionally you can enable fs-cache plugin for NFS, to cache often-used files on the node.
