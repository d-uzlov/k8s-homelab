
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
  dnfs \
  democratic-csi/democratic-csi \
  --version 0.14.1 \
  --values ./storage/democratic-csi/nfs/values.yaml \
  --namespace pv-dnfs \
  | sed -e '\!helm.sh/chart!d' -e '\!# Source:!d' -e '\!app.kubernetes.io/managed-by: Helm!d' -e '\!app.kubernetes.io/instance:!d' \
  > ./storage/democratic-csi/nfs/deployment.gen.yaml
```

# Environment setup

- Create Truenas Scale instance
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Setup local config:
```bash
cat <<EOF > ./storage/democratic-csi/nfs/env/truenas.env
host=ssd.tn.lan
# you get api key when creating it in truenas web ui
api_key=1-qwertyuiiopasdfghjklzxcvbnm

main_dataset=tank/k8s/nfs
# must be present in config but doesn't have to be valid
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi/nfs/env/truenas.env &&
sed \
  -e "s|REPLACE_ME_HOST|$host|g" \
  -e "s|REPLACE_ME_API_KEY|$api_key|g" \
  -e "s|REPLACE_ME_MAIN_DATASET|$main_dataset|g" \
  -e "s|REPLACE_ME_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi/nfs/config.template.yaml
) > ./storage/democratic-csi/nfs/env/config.yaml
```

# Deploy

```bash
kl create ns pv-dnfs
kl apply -k ./storage/democratic-csi/nfs/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-dnfs get pod
```

Test that deployment works:

```bash
kl apply -f ./storage/democratic-csi/nfs/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test-nfs-shared pod is running
kl get pod
# check contents of mounted folder, create a test file
kl exec deployments/test-nfs-fast -- touch /mnt/data/test-file
kl exec deployments/test-nfs-fast -- ls -laF /mnt/data
# cleanup resources
kl delete -f ./storage/democratic-csi/nfs/test.yaml
```
