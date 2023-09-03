
# Shared data

`shared` storage class is shared between namespaces.

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
