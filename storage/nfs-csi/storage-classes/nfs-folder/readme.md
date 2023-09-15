
# nfs-folder

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
mkdir -p ./storage/nfs-csi/storage-classes/nfs-folder/env
cat <<EOF > ./storage/nfs-csi/storage-classes/nfs-folder/env/nfs.env
server=truenas.lan
path=/mnt/main/k8s/nfs
EOF
```

# Deploy

```bash
kl apply -k ./storage/nfs-csi/storage-classes/nfs-folder
```

# Test that pods are able to consume PVCs

```bash
kl apply -f ./storage/nfs-csi/storage-classes/nfs-folder/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod
# check contents of mounted folder
kl exec deployments/test-nfs-folder -- touch /mnt/data/test-file
kl exec deployments/test-nfs-folder -- ls -laF /mnt/data
kl exec deployments/test-nfs-folder -- mount | grep /mnt/data
# cleanup resources
kl delete -f ./storage/nfs-csi/storage-classes/nfs-folder/test.yaml
```
