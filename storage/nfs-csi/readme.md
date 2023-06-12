
https://github.com/kubernetes-csi/csi-driver-nfs

# NFS CSI

This is s CSI plugin that can connect pods to remote NFS server.

# Deploy

```bash
kl create ns pv-nfs
kl apply -k ./storage/nfs-csi
```

# Create storage classes

You need to create storage classes with proper settings to connect to your NFS server.

```bash

# Init local settings
mkdir -p ./storage/nfs-csi/storage-classes/env
cat <<EOF > ./storage/nfs-csi/storage-classes/env/nfs.env
server=truenas.lan
path_bulk=/mnt/main/k8s
path_fast=/mnt/ssd/k8s
path_media=/mnt/main/k8s/media
EOF
kl apply -k ./storage/nfs-csi/storage-classes
```

# Cache

Optionally you can enable fs-cache plugin for NFS, to cache often-used files on the node.
