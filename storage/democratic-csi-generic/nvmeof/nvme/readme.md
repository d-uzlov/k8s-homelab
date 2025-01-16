
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
  dnvme \
  democratic-csi/democratic-csi \
  --version 0.14.7 \
  --values ./storage/democratic-csi-generic/nvmeof/values.yaml \
  --namespace pv-nvmeof \
  --set nameOverride=dnvme \
  --set fullnameOverride=dnvme \
  --set csiDriver.name=org.democratic-csi.nvmeof.nvme \
  --set driver.existingConfigSecret=dem-csi-config \
  --set storageClasses[0].name=nvme \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi-generic/nvmeof/nvme/deployment.gen.yaml
```

# Environment setup

Create a user for democratic-csi: [linux users](../../../../docs/linux-users.md).

Create an SSH key pair.
Put the private key into `./storage/democratic-csi-generic/nvmeof/nvme/env/ssh-key`.
Put the public key into `~/.ssh/authorized_keys` on the server.

On the server: make sure nvmeof is enabled and nvmetcli is installed.
On the client: instal `nvme-cli` package.

Create dataset for volumes.
For example: `tank/k8s/nvmeof`

Setup local config:

```bash
mkdir -p ./storage/democratic-csi-generic/nvmeof/nvme/env/
 cat << EOF > ./storage/democratic-csi-generic/nvmeof/nvme/env/config.env
host=server.address
ssh_user=democratic-csi

main_dataset=tank/k8s/nvmeof
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi-generic/nvmeof/nvme/env/config.env &&
sed \
  -e "s|AUTOREPLACE_SERVER_ADDRESS|$host|g" \
  -e "s|AUTOREPLACE_SSH_USER|$ssh_user|g" \
  -e "s|AUTOREPLACE_MAIN_DATASET|$main_dataset|g" \
  -e "s|AUTOREPLACE_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi-generic/nvmeof/config.template.yaml &&
sed -e 's/^/    /' ./storage/democratic-csi-generic/nvmeof/nvme/env/ssh-key
) > ./storage/democratic-csi-generic/nvmeof/nvme/env/config.yaml
```

# Deploy

```bash
kl create ns pv-nvmeof
kl label ns pv-nvmeof pod-security.kubernetes.io/enforce=privileged

kl -n pv-nvmeof apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-nvmeof apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/democratic-csi-generic/nvmeof/nvme/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-nvmeof get pod -o wide
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/nvmeof/nvme/
kl delete ns pv-nvmeof
```

# Test that deployment works

```bash
kl apply -f ./storage/democratic-csi-generic/nvmeof/nvme/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod -o wide

# if there are issues, you can try to check logs
kl describe pvc test-nvme
kl -n pv-nvmeof logs deployments/dnvme-controller csi-driver --tail 20
kl describe pod -l app=test-nvmeof

# check mounted file system
kl exec deployments/test-nvmeof -- mount | grep /mnt/data
kl exec deployments/test-nvmeof -- df -h /mnt/data
kl exec deployments/test-nvmeof -- touch /mnt/data/test-file
kl exec deployments/test-nvmeof -- ls -laF /mnt/data

# explore container
kl exec deployments/test-nvmeof-root -it -- sh

# cleanup resources
kl delete -f ./storage/democratic-csi-generic/nvmeof/nvme/test.yaml
```
