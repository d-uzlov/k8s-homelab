
# SMB-CSI

This is s CSI plugin that can connect pods to a remote SMB server.

# Generate config

You only need to do this when updating the app.

```bash
helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts

helm repo update csi-driver-smb
helm search repo csi-driver-smb/csi-driver-smb --versions --devel | head
helm show values csi-driver-smb/csi-driver-smb > ./storage/smb-csi/default-values.yaml
```

```bash
helm template \
  csi-smb \
  csi-driver-smb/csi-driver-smb \
  --version v1.12.0 \
  --values ./storage/smb-csi/values.yaml \
  --namespace pv-smb \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/smb-csi/deployment.gen.yaml
```

# Deploy

```bash
kl create ns pv-smb
kl apply -k ./storage/smb-csi
kl -n pv-smb get pod
```
