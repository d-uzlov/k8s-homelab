
# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi > ./storage/democratic-csi/default-values.yaml
```

```bash
helm template \
  discsi \
  democratic-csi/democratic-csi \
  --version 0.14.1 \
  --values ./storage/democratic-csi/iscsi/values.yaml \
  --namespace pv-discsi \
  --set nameOverride=discsi \
  --set fullnameOverride=discsi \
  --set csiDriver.name=org.democratic-csi.iscsi.block \
  --set driver.existingConfigSecret=freenas-api-iscsi-conf \
  --set storageClasses[0].name=block \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi/iscsi/block/deployment.gen.yaml
```

# Environment setup

- Create Truenas Scale instance
- Create dataset for iSCSI shares
- Enable iSCSI service
- Create iSCSI portal (simple case: no auth, listen on 0.0.0.0)
- Create initiator group (simple case: check "Allow all initiators")
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Setup local config:
```bash
cat <<EOF > ./storage/democratic-csi/iscsi/block/env/truenas.env
host=truenas.lan
# you get the api key when you create it in the truenas web ui
api_key=1-qwertyuiiopasdfghjklzxcvbnm

main_dataset=tank/k8s/iscsi
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi/iscsi/block/env/truenas.env &&
sed \
  -e "s|REPLACE_ME_HOST|$host|g" \
  -e "s|REPLACE_ME_API_KEY|$api_key|g" \
  -e "s|REPLACE_ME_MAIN_DATASET|$main_dataset|g" \
  -e "s|REPLACE_ME_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi/iscsi/config.template.yaml
) > ./storage/democratic-csi/iscsi/block/env/config.yaml
```

# Deploy

```bash
kl create ns pv-discsi
kl apply -k ./storage/democratic-csi/iscsi/block/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-discsi get pod
```

Test that deployment works:

```bash
kl apply -f ./storage/democratic-csi/iscsi/block/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod

# if there are issues, you can try to check driver logs
kl -n pv-discsi logs deployments/discsi-controller csi-driver --tail 20 > iscsi.log

# check contents of mounted folder, create a test file
kl exec deployments/test-iscsi-block -- touch /mnt/data/test-file
kl exec deployments/test-iscsi-block -- ls -laF /mnt/data
# cleanup resources
kl delete -f ./storage/democratic-csi/iscsi/block/test.yaml
```
