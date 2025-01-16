
# fast

`fast` storage class provides non-shared data volumes.

# Init server

- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- Create SMB share for chosen folder
- - In this example: `k8s`

# Init local settings

```bash
mkdir -p ./storage/smb-csi/storage-classes/fast/env
 cat << EOF > ./storage/smb-csi/storage-classes/fast/env/smb.env
server=truenas.lan
share=k8s
EOF
```

# Deploy

```bash
kl apply -k ./storage/smb-csi/storage-classes/fast/
```

# Test that pods are able to consume PVCs

```bash
kl apply -f ./storage/smb-csi/storage-classes/fast/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod
# check contents of mounted folder
kl exec deployments/test-smb-fast -- touch /mnt/data/test-file
kl exec deployments/test-smb-fast -- ls -laF /mnt/data
kl exec deployments/test-smb-fast -- mount | grep /mnt/data
# cleanup resources
kl delete -f ./storage/smb-csi/storage-classes/fast/test.yaml
```
