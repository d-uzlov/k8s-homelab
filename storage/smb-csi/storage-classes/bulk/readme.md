
# bulk

# Init server

- Get static server address (either static IP or a DNS record)
- - In this example: `truenas.lan`
- Create folder for sharing
- Create SMB share for chosen folder
- - In this example: `k8s`

# Init local settings

```bash
mkdir -p ./storage/smb-csi/storage-classes/bulk/env
cat <<EOF > ./storage/smb-csi/storage-classes/bulk/env/smb.env
server=truenas.lan
share=k8s
EOF
```

# Deploy

```bash
kl apply -k ./storage/smb-csi/storage-classes/bulk/
```

# Test that pods are able to consume PVCs

```bash
kl apply -f ./storage/smb-csi/storage-classes/bulk/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod
# check contents of mounted folder
kl exec deployments/test-smb-bulk -- touch /mnt/data/test-file
kl exec deployments/test-smb-bulk -- ls -laF /mnt/data
kl exec deployments/test-smb-bulk -- mount | grep /mnt/data
# cleanup resources
kl delete -f ./storage/smb-csi/storage-classes/bulk/test.yaml
```
