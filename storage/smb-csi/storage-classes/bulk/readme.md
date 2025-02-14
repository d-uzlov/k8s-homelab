
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
 cat << EOF > ./storage/smb-csi/storage-classes/bulk/env/smb.env
server=truenas.lan
share=k8s
EOF
```

# Deploy

```bash
kl apply -k ./storage/smb-csi/storage-classes/bulk/
```
