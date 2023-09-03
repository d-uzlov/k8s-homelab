
https://github.com/kubernetes-csi/csi-driver-nfs

# NFS CSI

This is s CSI plugin that can connect pods to remote NFS server.

# Deploy

```bash
kl create ns pv-nfs
kl apply -k ./storage/nfs-csi
```

Don't forget to enable NFSv4 protocol on the server side.

# Create storage classes

You need to create storage classes with proper settings to connect to your NFS server.

References:
- [storage-classes](./storage-classes/readme.md)

# Cache

Optionally you can enable fs-cache plugin for NFS, to cache often-used files on the node.
