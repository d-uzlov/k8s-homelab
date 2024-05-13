
# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi --version 0.14.6 > ./storage/democratic-csi/default-values.yaml
```

```bash
helm template \
  dnfsb \
  democratic-csi/democratic-csi \
  --version 0.14.6 \
  --values ./storage/democratic-csi/nfs/values.yaml \
  --namespace pv-dnfsb \
  --set nameOverride=dnfsb \
  --set fullnameOverride=dnfsb \
  --set csiDriver.name=org.democratic-csi.nfs.bulk \
  --set driver.existingConfigSecret=freenas-api-nfs-bulk-conf \
  --set storageClasses[0].name=bulk \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi/nfs/bulk/deployment.gen.yaml
```

# Environment setup

- Create Truenas Scale instance
- Create dataset for NFS shares
- - Make sure that you don't share this dataset or any of its parent datasets via nfs
- - If there is an common share you will get an error like this:
- - `<pvc dataset path> is a subtree of <parent NFS share path> and already exports this dataset for 'everybody'`
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Setup local config:
```bash
cat <<EOF > ./storage/democratic-csi/nfs/bulk/env/truenas.env
host=truenas.lan
# you get the api key when you create it in the truenas web ui
api_key=1-qwertyuiiopasdfghjklzxcvbnm

main_dataset=tank/k8s/nfs
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi/nfs/bulk/env/truenas.env &&
sed \
  -e "s|REPLACE_ME_HOST|$host|g" \
  -e "s|REPLACE_ME_API_KEY|$api_key|g" \
  -e "s|REPLACE_ME_MAIN_DATASET|$main_dataset|g" \
  -e "s|REPLACE_ME_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi/nfs/config.template.yaml
) > ./storage/democratic-csi/nfs/bulk/env/config.yaml
```

# Deploy

```bash
kl create ns pv-dnfsb
kl label ns pv-dnfsb pod-security.kubernetes.io/enforce=privileged

kl -n pv-dnfsb apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dnfsb apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/democratic-csi/nfs/bulk/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-dnfsb get pod -o wide
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi/nfs/bulk/
kl delete ns pv-dnfsb
```

# Test that deployment works

```bash
kl apply -f ./storage/democratic-csi/nfs/bulk/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod -o wide

# if there are issues, you can try to check logs
kl describe pvc test-nfs-bulk
kl -n pv-dnfsb logs deployments/dnfsb-controller csi-driver --tail 20

# check contents of mounted folder, create a test file
kl exec deployments/test-nfs-bulk -- mount | grep /mnt/data
kl exec deployments/test-nfs-bulk -- df -h /mnt/data
kl exec deployments/test-nfs-bulk -- touch /mnt/data/test-file
kl exec deployments/test-nfs-bulk -- ls -laF /mnt/data

# cleanup resources
kl delete -f ./storage/democratic-csi/nfs/bulk/test.yaml
```
