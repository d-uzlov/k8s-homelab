
# Storage classes for the proxy driver

Unlike other democratic-csi drivers, this one can have many storage classes.

Here we define iscsi, nvmeof and nfs storage classes
that connect to the server via `zfs-generic-*` drivers,
and put all storage classes into the same `mainDataset`.

If you want more servers, repeat this setup.

# Custom drivers

If you want to use other drivers, just copy
the `storage-class.template.yaml` into `env` folder,
create your secret with config for your driver
with key(s) starting with `config-`
and point storage class to that secret.

You can either place the whole config in one key,
or split it into several keys.
Make sure that all annotations point to your secret.

# Environment setup

Create dataset for volumes.
For example: `tank/k8s`

Setup connection settings config:

```bash
mkdir -p ./storage/democratic-csi-generic/proxy/storage-classes/env/

serverAddress=
sshUser=democratic-csi
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
snapshotDataset=invalid

sed \
  -e "s|AUTOREPLACE_MAIN_DATASET|$mainDataset|g" \
  -e "s|AUTOREPLACE_SNAP_DATASET|$snapshotDataset|g" \
  -e "s|AUTOREPLACE_SERVER_ADDRESS|$serverAddress|g" \
  -e "s|AUTOREPLACE_SSH_USER|$sshUser|g" \
  ./storage/democratic-csi-generic/proxy/storage-classes/connection.template.yaml \
  > ./storage/democratic-csi-generic/proxy/storage-classes/env/$serverAddress-connection.yaml

cat << EOF > ./storage/democratic-csi-generic/proxy/storage-classes/env/$serverAddress-ssh-key.yaml
sshConnection:
  privateKey: |
EOF
sed -e 's/^/    /' ./storage/democratic-csi-generic/proxy/env/ssh-key >> ./storage/democratic-csi-generic/proxy/storage-classes/env/$serverAddress-ssh-key.yaml

```

# Create storage classes

```bash
serverAddress=
# optionally, add a prefix
# storageClassPrefix=server-

rm -f ./storage/democratic-csi-generic/proxy/storage-classes/env/resources-$serverAddress.yaml
rm -f ./storage/democratic-csi-generic/proxy/storage-classes/env/secrets-$serverAddress.yaml
drivers="zfs-generic-nfs zfs-generic-iscsi zfs-generic-smb zfs-generic-nvmeof"
for driver in $drivers; do
  shortName=${driver#zfs-generic-}
  scName=$storageClassPrefix$shortName
  secretName=$serverAddress-$scName-config
  sed \
    -e "s|AUTOREPLACE_SECRET_NAME|$secretName|g" \
    -e "s|AUTOREPLACE_STORAGE_CLASS_NAME|$scName|g" \
    ./storage/democratic-csi-generic/proxy/storage-classes/storage-class.template.yaml \
    > ./storage/democratic-csi-generic/proxy/storage-classes/env/sc-$serverAddress-$scName.yaml
  sed \
    -e "s|AUTOREPLACE_TEST_NAME|test-$scName|g" \
    -e "s|AUTOREPLACE_STORAGE_CLASS|$scName|g" \
    -e "s|AUTOREPLACE_PVC_MODE|ReadWriteOnce|g" \
    ./storage/democratic-csi-generic/proxy/storage-classes/test.template.yaml \
    > ./storage/democratic-csi-generic/proxy/storage-classes/env/test-$scName.yaml
  echo "- ./sc-$serverAddress-$scName.yaml" >> ./storage/democratic-csi-generic/proxy/storage-classes/env/resources-$serverAddress.yaml
  cat << EOF >> ./storage/democratic-csi-generic/proxy/storage-classes/env/secrets-$serverAddress.yaml
- name: $secretName
  namespace: pv-dcsi
  files:
  - config-connection=./$serverAddress-connection.yaml
  - config-ssh-key=./$serverAddress-ssh-key.yaml
  literals:
  - 'config-driver=driver: $driver'
  options:
    disableNameSuffixHash: true
EOF
done
cat << EOF >> ./storage/democratic-csi-generic/proxy/storage-classes/env/sc-$serverAddress-iscsi.yaml
  fsType: ext4
mountOptions:
- noatime
- discard
EOF
cat << EOF >> ./storage/democratic-csi-generic/proxy/storage-classes/env/sc-$serverAddress-nvmeof.yaml
  fsType: ext4
mountOptions:
- noatime
- discard
EOF
cat << EOF >> ./storage/democratic-csi-generic/proxy/storage-classes/env/sc-$serverAddress-nfs.yaml
  fsType: nfs
mountOptions:
- soft
- noatime
- rsize=262144
- wsize=262144
EOF
cat << EOF >> ./storage/democratic-csi-generic/proxy/storage-classes/env/sc-$serverAddress-smb.yaml
  fsType: smb3
mountOptions:
# - file_mode=0777
# - dir_mode=0777
- uid=1000
# gid is set automatically when using fsGroup
# - gid=1000
- soft
- cifsacl
# unix option is not supportd by samba as of truenas scale 22.12
# - unix
- mfsymlinks
- seal
EOF

```

You can delete or comment lines that you don't need
from `storage-classes/env/resources-$serverAddress`.

I didn't manage to make SMB work.
Config here can be a starting point.
`zfs-generic-smb` driver just sets `sharesmb=on`, which does not allow guest access.
At a glance I don't see a way to specify username and password for samba in democratic-csi.
Maybe there are some undocumented parameters that can be put into `node-stage-secret` for this.

If you need SMB and don't want to figure out how to fix it here,
check out [smb-csi](../../../smb-csi/readme.md)

# Deploy

```bash

(
echo "---"
echo "apiVersion: kustomize.config.k8s.io/v1beta1"
echo "kind: Kustomization"
echo "resources:"
cat ./storage/democratic-csi-generic/proxy/storage-classes/env/resources-*
echo secretGenerator:
cat ./storage/democratic-csi-generic/proxy/storage-classes/env/secrets-*
) > ./storage/democratic-csi-generic/proxy/storage-classes/env/kustomization.yaml

kl apply -k ./storage/democratic-csi-generic/proxy/storage-classes/env/

kl get sc
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/proxy/storage-classes/env/
```

# Test that deployment works

```bash
cat ./storage/democratic-csi-generic/proxy/storage-classes/env/test-* | kl apply -f -
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pods are running
kl get pod -o wide

(cd ./storage/democratic-csi-generic/proxy/storage-classes/env/ && ll test-* | sed s~.yaml~~)
# select one of the tests to get details
testName=
echo $testName

# if there are issues, you can try to check logs
kl describe pvc $testName
kl -n pv-dcsi logs deployments/dcsi-controller csi-driver --tail 20
kl describe pod -l app=$testName

# check mounted file system
kl exec deployments/$testName -- mount | grep /mnt/data
kl exec deployments/$testName -- df -h /mnt/data
kl exec deployments/$testName -- touch /mnt/data/test-file
kl exec deployments/$testName -- ls -laF /mnt/data

# explore container
kl exec deployments/$testName-root -it -- sh

# cleanup resources
cat ./storage/democratic-csi-generic/proxy/storage-classes/env/test-* | kl delete -f -
```
