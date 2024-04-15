
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
  dnfsf \
  democratic-csi/democratic-csi \
  --version 0.14.6 \
  --values ./storage/democratic-csi/nfs/values.yaml \
  --namespace pv-dnfsf \
  --set nameOverride=dnfsf \
  --set fullnameOverride=dnfsf \
  --set csiDriver.name=org.democratic-csi.nfs.fast \
  --set driver.existingConfigSecret=freenas-api-nfs-conf \
  --set storageClasses[0].name=fast \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi/nfs/fast/deployment.gen.yaml
```

# Environment setup

- Create Truenas Scale instance
- Create dataset for NFS shares
- - Make sure that you don't share this dataset or any of its parent datasets via nfs
- - If there is an common share you will get an error like this:
- - `<pvc dataset path> is a subtree of <parent NFS share path> and already exports this dataset for 'everybody'`
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Create at least one NFS share and enable NFS service
- - It seems like it's not possible to enable the service if you don't have shares yet
- Setup local config:
```bash
cat <<EOF > ./storage/democratic-csi/nfs/fast/env/truenas.env
host=truenas.lan
# you get the api key when you create it in the truenas web ui
api_key=1-qwertyuiiopasdfghjklzxcvbnm

main_dataset=tank/k8s/nfs
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi/nfs/fast/env/truenas.env &&
sed \
  -e "s|REPLACE_ME_HOST|$host|g" \
  -e "s|REPLACE_ME_API_KEY|$api_key|g" \
  -e "s|REPLACE_ME_MAIN_DATASET|$main_dataset|g" \
  -e "s|REPLACE_ME_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi/nfs/config.template.yaml
) > ./storage/democratic-csi/nfs/fast/env/config.yaml
```

# Deploy

```bash
kl create ns pv-dnfsf
kl label ns pv-dnfsf pod-security.kubernetes.io/enforce=privileged

kl apply -k ./storage/democratic-csi/nfs/fast/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-dnfsf get pod -o wide
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi/nfs/fast/
kl delete ns pv-dnfsf
```

# Test that deployment works

```bash
kl apply -f ./storage/democratic-csi/nfs/fast/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod -o wide

# if there are issues, you can try to check logs
kl describe pvc test-nfs-fast
kl -n pv-dnfsf logs deployments/dnfsf-controller csi-driver --tail 20

# check contents of mounted folder, create a test file
kl exec deployments/test-nfs-fast -- mount | grep /mnt/data
kl exec deployments/test-nfs-fast -- df -h /mnt/data
kl exec deployments/test-nfs-fast -- touch /mnt/data/test-file
kl exec deployments/test-nfs-fast -- ls -laF /mnt/data

# cleanup resources
kl delete -f ./storage/democratic-csi/nfs/fast/test.yaml
```
