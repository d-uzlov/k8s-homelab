
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
  dnfs \
  democratic-csi/democratic-csi \
  --version 0.14.7 \
  --values ./storage/democratic-csi-generic/nfs/values.yaml \
  --namespace pv-dnfs \
  --set nameOverride=dnfs \
  --set fullnameOverride=dnfs \
  --set csiDriver.name=org.democratic-csi.nfs.nfs \
  --set driver.existingConfigSecret=dem-csi-config \
  --set storageClasses[0].name=nfs \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' \
  > ./storage/democratic-csi-generic/nfs/nfs/deployment.gen.yaml
```

# Environment setup

Create a user for democratic-csi: [linux users](../../../../docs/linux-users.md).
Disable motd for the user: `touch ~/.hushlogin`.
Make sure to enable passwordless sudo for the user.

Create an SSH key pair.
Put the private key into `./storage/democratic-csi-generic/nfs/nfs/env/ssh-key`.
Put the public key into `~/.ssh/authorized_keys` on the server.

On the server: install `nfs-kernel-server` package.
On the client: instal `nvme-cli` package.

Create dataset for volumes.
For example: `tank/k8s/nfs`

Setup local config:

```bash
mkdir -p ./storage/democratic-csi-generic/nfs/nfs/env/
cat <<EOF > ./storage/democratic-csi-generic/nfs/nfs/env/config.env
host=server.address
ssh_user=democratic-csi

main_dataset=tank/k8s/nfs
# must be present in config
# needs to be valid if you use volumeSnapshotClasses in values.yaml
# can be whatever if you don't
snapshot_dataset=nonexistent
EOF

(. ./storage/democratic-csi-generic/nfs/nfs/env/config.env &&
sed \
  -e "s|AUTOREPLACE_SERVER_ADDRESS|$host|g" \
  -e "s|AUTOREPLACE_SSH_USER|$ssh_user|g" \
  -e "s|AUTOREPLACE_MAIN_DATASET|$main_dataset|g" \
  -e "s|AUTOREPLACE_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi-generic/nfs/config.template.yaml &&
sed -e 's/^/    /' ./storage/democratic-csi-generic/nfs/nfs/env/ssh-key
) > ./storage/democratic-csi-generic/nfs/nfs/env/config.yaml
```

# Deploy

```bash
kl create ns pv-dnfs
kl label ns pv-dnfs pod-security.kubernetes.io/enforce=privileged

kl -n pv-dnfs apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dnfs apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/democratic-csi-generic/nfs/nfs/
# make sure that all democratic-csi pods are running
# there can be some restarts at first,
# but eventually it should be running without restarts
kl -n pv-dnfs get pod -o wide
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/nfs/nfs/
kl delete ns pv-dnfs
```

# Test that deployment works

```bash
kl apply -f ./storage/democratic-csi-generic/nfs/nfs/test.yaml
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pod is running
kl get pod -o wide

# if there are issues, you can try to check logs
kl describe pvc test-dnfs
kl -n pv-dnfs logs deployments/dnfs-controller csi-driver --tail 20
kl describe pod -l app=test-dnfs

# check mounted file system
kl exec deployments/test-dnfs -- mount | grep /mnt/data
kl exec deployments/test-dnfs -- df -h /mnt/data
kl exec deployments/test-dnfs -- touch /mnt/data/test-file
kl exec deployments/test-dnfs -- ls -laFh /mnt/data

# explore container
kl exec deployments/test-dnfs-root -it -- sh

# cleanup resources
kl delete -f ./storage/democratic-csi-generic/nfs/nfs/test.yaml
```
