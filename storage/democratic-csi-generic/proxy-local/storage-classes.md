
# Storage classes for the proxy driver

Unlike other democratic-csi drivers, this one can have many storage classes.

Here we define iscsi, nvmeof and nfs storage classes
that connect to the server via `zfs-generic-*` drivers.

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

# NVMEoF

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/

storageClassName=test-nvme-sc
connectionName=$storageClassName
serverAddress=test.example.com
sshUser=democratic-csi
sshKey=./storage/democratic-csi-generic/proxy/env/ssh-key
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
# doesn't need to be a real dataset if you don't want to use detached snapshots
snapshotDataset=invalid

nqnBaseName=nqn.2025-01.com.example:location:nas-nickname
nqnPrefix=k8s-cluster-nickname:

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName-connection.yaml
driver: zfs-generic-nvmeof

zfs:
  # main and snapshot datasets should not be nested in each other
  datasetParentName: $mainDataset
  detachedSnapshotsDatasetParentName: $snapshotDataset

# final nqn format:
# {{ nvmeof.shareStrategyNvmetCli.basename }}:{{ nvmeof.namePrefix }}{{ nvmeof.nameTemplate }}{{ nvmeof.nameSuffix }}
nvmeof:
  transports: # connection from node
  - tcp://$serverAddress:4420
  namePrefix: '$nqnPrefix'
  shareStrategyNvmetCli:
    basename: $nqnBaseName

sshConnection: # connection from controller
  host: $serverAddress
  port: 22
  username: $sshUser
  privateKey: |
$(sed -e 's/^/    /' $sshKey)
EOF

cat << EOF > ./storage/democratic-csi-generic/proxy/env/$storageClassName-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $storageClassName
provisioner: org.democratic-csi.proxy
allowVolumeExpansion: true
parameters:
  connection: $connectionName
  fsType: ext4
mountOptions:
- noatime
- discard
EOF

```

# iSCSI

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/

storageClassName=test-nvme-sc
connectionName=$storageClassName
serverAddress=test.example.com
sshUser=democratic-csi
sshKey=./storage/democratic-csi-generic/proxy/env/ssh-key
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
# doesn't need to be a real dataset if you don't want to use detached snapshots
snapshotDataset=invalid

iqnBaseName=iqn.2025-01.com.example:location:nas-nickname
iqnPrefix=k8s-cluster-nickname:

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName-connection.yaml
driver: zfs-generic-nvmeof

zfs:
  # main and snapshot datasets should not be nested in each other
  datasetParentName: $mainDataset
  detachedSnapshotsDatasetParentName: $snapshotDataset

# final nqn format:
# {{ nvmeof.shareStrategyNvmetCli.basename }}:{{ nvmeof.namePrefix }}{{ nvmeof.nameTemplate }}{{ nvmeof.nameSuffix }}
nvmeof:
  transports: # connection from node
  - tcp://$serverAddress:4420
  namePrefix: '$nqnPrefix'
  shareStrategyNvmetCli:
    basename: $nqnBaseName

iscsi:
  # connection from node
  targetPortal: $serverAddress
  namePrefix: '$iqnPrefix'
  shareStrategyTargetCli:
    basename: $iqnBaseName

sshConnection: # connection from controller
  host: $serverAddress
  port: 22
  username: $sshUser
  privateKey: |
$(sed -e 's/^/    /' $sshKey)
EOF

cat << EOF > ./storage/democratic-csi-generic/proxy/env/$storageClassName-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $storageClassName
provisioner: org.democratic-csi.proxy
allowVolumeExpansion: true
parameters:
  connection: $connectionName
  fsType: ext4
mountOptions:
- noatime
- discard
EOF

```

# NFS

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/

storageClassName=test-nvme-sc
connectionName=$storageClassName
serverAddress=test.example.com
sshUser=democratic-csi
sshKey=./storage/democratic-csi-generic/proxy/env/ssh-key
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
# doesn't need to be a real dataset if you don't want to use detached snapshots
snapshotDataset=invalid

nqnBaseName=nqn.2025-01.com.example:location:nas-nickname
nqnPrefix=k8s-cluster-nickname:

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName-connection.yaml
driver: zfs-generic-nvmeof

zfs:
  # main and snapshot datasets should not be nested in each other
  datasetParentName: $mainDataset
  detachedSnapshotsDatasetParentName: $snapshotDataset

nfs:
  shareHost: $serverAddress

sshConnection: # connection from controller
  host: $serverAddress
  port: 22
  username: $sshUser
  privateKey: |
$(sed -e 's/^/    /' $sshKey)
EOF

cat << EOF > ./storage/democratic-csi-generic/proxy/env/$storageClassName-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $storageClassName
provisioner: org.democratic-csi.proxy
allowVolumeExpansion: true
parameters:
  connection: $connectionName
  fsType: nfs
mountOptions:
- soft
- noatime
- rsize=262144
- wsize=262144
EOF

```

# Create storage classes

Create `storage/democratic-csi-generic/proxy/env/kustomization.yaml`.

Kustomization fila example:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: pv-dem

resources:
- ./my-nas-nvmeof.yaml
- ./my-nas-nfs.yaml

secretGenerator:
- name: connections
  files:
  - my-nas-nvmeof.yaml=./connections/my-nas-nvmeof.yaml
  - my-nas-nfs.yaml=./connections/my-nas-nfs.yaml
  options:
    disableNameSuffixHash: true
```

# Deploy

TODO finish this

```bash

# (
# echo "---"
# echo "apiVersion: kustomize.config.k8s.io/v1beta1"
# echo "kind: Kustomization"
# echo "resources:"
# cat ./storage/democratic-csi-generic/proxy/env/resources-*
# echo secretGenerator:
# cat ./storage/democratic-csi-generic/proxy/env/secrets-*
# ) > ./storage/democratic-csi-generic/proxy/env/kustomization.yaml

# kl apply -k ./storage/democratic-csi-generic/proxy/env/

kl get sc
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/proxy/env/
```
