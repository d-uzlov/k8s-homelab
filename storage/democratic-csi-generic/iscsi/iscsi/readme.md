
# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi --version 0.14.7 > ./storage/democratic-csi-generic/default-values.yaml
```

```bash
helm template \
  iscsi \
  democratic-csi/democratic-csi \
  --version 0.14.7 \
  --values ./storage/democratic-csi-generic/iscsi/values.yaml \
  --namespace pv-iscsi \
  --set nameOverride=iscsi \
  --set fullnameOverride=iscsi \
  --set csiDriver.name=org.democratic-csi.iscsi.iscsi \
  --set driver.existingConfigSecret=dem-csi-config \
  --set storageClasses[0].name=iscsi \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi-generic/iscsi/iscsi/deployment.gen.yaml
```

# Environment setup

Create a user for democratic-csi: [linux users](../../../../docs/linux-users.md).

Create an SSH key pair.
Put the private key into `./storage/democratic-csi-generic/iscsi/iscsi/env/ssh-key`.
Put the public key into `~/.ssh/authorized_keys` on the server.

On the server: make sure targetcli is installed.
On the client: instal `open-iscsi` package.

Create dataset for volumes.
For example: `tank/k8s/iscsi`

Setup local config:

```bash
mkdir -p ./storage/democratic-csi-generic/iscsi/iscsi/env/
cat << EOF > ./storage/democratic-csi-generic/iscsi/iscsi/env/config.env
host=server.address
ssh_user=democratic-csi

main_dataset=tank/k8s/iscsi
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi-generic/iscsi/iscsi/env/config.env &&
sed \
  -e "s|AUTOREPLACE_SERVER_ADDRESS|$host|g" \
  -e "s|AUTOREPLACE_SSH_USER|$ssh_user|g" \
  -e "s|AUTOREPLACE_MAIN_DATASET|$main_dataset|g" \
  -e "s|AUTOREPLACE_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi-generic/iscsi/config.template.yaml &&
sed -e 's/^/    /' ./storage/democratic-csi-generic/iscsi/iscsi/env/ssh-key
) > ./storage/democratic-csi-generic/iscsi/iscsi/env/config.yaml
```

# Deploy

```bash
kl create ns pv-iscsi
kl label ns pv-iscsi pod-security.kubernetes.io/enforce=privileged

kl -n pv-iscsi apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-iscsi apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/democratic-csi-generic/iscsi/iscsi/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-iscsi get pod -o wide
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/iscsi/iscsi/
kl delete ns pv-iscsi
```

# Test that deployment works

```bash
kl apply -f ./storage/democratic-csi-generic/iscsi/iscsi/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod -o wide

# if there are issues, you can try to check logs
kl describe pvc test-iscsi
kl -n pv-iscsi logs deployments/iscsi-controller csi-driver --tail 20
kl describe pod -l app=test-iscsi

# check mounted file system
kl exec deployments/test-iscsi -- mount | grep /mnt/data
kl exec deployments/test-iscsi -- df -h /mnt/data
kl exec deployments/test-iscsi -- touch /mnt/data/test-file
kl exec deployments/test-iscsi -- ls -laF /mnt/data

# explore container
kl exec deployments/test-iscsi-root -it -- sh

# cleanup resources
kl delete -f ./storage/democratic-csi-generic/iscsi/iscsi/test.yaml
```
