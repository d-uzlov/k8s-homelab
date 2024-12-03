
# shared

`shared` storage class is shared between namespaces.

# Init server

- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- - In this example: `/mnt/main/k8s/media`
- Create NFS share for chosen folder
- Set `Mapall User` and `Mapall Group` to `nobody` and `nogroup` respectively
- - This way different apps will all have access to shared data, regardless of their local user

# Init local settings

```bash
mkdir -p ./storage/nfs-csi/storage-classes/shared/env
cat <<EOF > ./storage/nfs-csi/storage-classes/shared/env/nfs.env
server=truenas.lan
path=/mnt/main/k8s/media
EOF
```

# Deploy

```bash
kl apply -k ./storage/nfs-csi/storage-classes/shared/
```

# Test that pods are able to consume PVCs

```bash
kl apply -f ./storage/nfs-csi/storage-classes/shared/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod

# check contents of mounted folder
kl exec deployments/test-nfs-shared -- mount | grep /mnt/data
kl exec deployments/test-nfs-shared -- df -h /mnt/data
kl exec deployments/test-nfs-shared -- touch /mnt/data/test-file
kl exec deployments/test-nfs-shared -- ls -laF /mnt/data

# cleanup resources
kl delete -f ./storage/nfs-csi/storage-classes/shared/test.yaml
```
