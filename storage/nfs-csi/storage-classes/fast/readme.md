
# fast

# Init server

- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- - In this example: `/mnt/main/k8s/nfs`
- Create NFS share for chosen folder
- Set `Maproot User` and `Maproot Group` to `root`
- - This is required to allow NFS CSI controller to set up folder permissions,
and to delete application data that doesn't enable write access to world

# Init local settings

```bash
mkdir -p ./storage/nfs-csi/storage-classes/fast/env
 cat << EOF > ./storage/nfs-csi/storage-classes/fast/env/nfs.env
server=truenas.lan
path=/mnt/main/k8s/nfs
EOF
```

# Deploy

```bash
kl apply -k ./storage/nfs-csi/storage-classes/fast
```
