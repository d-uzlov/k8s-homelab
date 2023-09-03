
# Shared data

`shared` storage class is shared between namespaces.

Init server:
- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- - In this example: `/mnt/main/k8s/media`
- Create NFS share for chosen folder
- Set `Mapall User` and `Mapall Group` to `nobody` and `nogroup` respectively
- - This way different apps will all have access to shared data, regardless of their local user

Init local settings:

```bash
mkdir -p ./storage/nfs-csi/storage-classes/shared/env
cat <<EOF > ./storage/nfs-csi/storage-classes/shared/env/nfs.env
server=truenas.lan
path=/mnt/main/k8s/media
EOF
```

Deploy:

```bash
kl apply -k ./storage/nfs-csi/storage-classes/shared
```

Test that pods are able to consume PVCs of media class:

```bash
kl apply -f ./storage/nfs-csi/storage-classes/shared/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test-nfs-shared pod is running
kl get pod
# check contents of mounted folder
kl exec deployments/test-nfs-shared -- ls -laF /mnt/data
# cleanup resources
kl delete -f ./storage/nfs-csi/storage-classes/shared/test.yaml
```

# Bulk

`bulk` storage class provides non-shared data volumes,
with optional persistence across re-deployments.

Init server:
- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- - In this example: `/mnt/main/k8s/nfs`
- Create NFS share for chosen folder
- Set `Maproot User` and `Maproot Group` to `root`
- - This is required to allow NFS CSI controller to set up folder permissions,
and to delete application data that doesn't enable write access to world

Init local settings:

```bash
mkdir -p ./storage/nfs-csi/storage-classes/bulk/env
cat <<EOF > ./storage/nfs-csi/storage-classes/bulk/env/nfs.env
server=truenas.lan
path=/mnt/main/k8s/nfs
EOF
```

Deploy:

```bash
kl apply -k ./storage/nfs-csi/storage-classes/bulk
```

Test that pods are able to consume PVCs of media class:

```bash
kl apply -f ./storage/nfs-csi/storage-classes/bulk/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test-nfs-bulk pod is running
kl get pod
# check contents of mounted folder
kl exec deployments/test-nfs-bulk -- ls -laF /mnt/data
# cleanup resources
kl delete -f ./storage/nfs-csi/storage-classes/bulk/test.yaml
```
