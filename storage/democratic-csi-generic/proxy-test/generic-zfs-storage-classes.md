
# NVMEoF

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/
mkdir -p ./storage/democratic-csi-generic/proxy/env/storage-classes/

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

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName.yaml
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

cat << EOF > ./storage/democratic-csi-generic/proxy/env/storage-classes/$storageClassName-sc.yaml
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
mkdir -p ./storage/democratic-csi-generic/proxy/env/storage-classes/

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

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName.yaml
driver: zfs-generic-nvmeof

zfs:
  # main and snapshot datasets should not be nested in each other
  datasetParentName: $mainDataset
  detachedSnapshotsDatasetParentName: $snapshotDataset

# final iqn format:
# {{ iscsi.shareStrategyTargetCli.basename }}:{{ iscsi.namePrefix }}{{ iscsi.nameTemplate }}{{ iscsi.nameSuffix }}
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

cat << EOF > ./storage/democratic-csi-generic/proxy/env/storage-classes/$storageClassName-sc.yaml
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
mkdir -p ./storage/democratic-csi-generic/proxy/env/storage-classes/

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

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName.yaml
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

cat << EOF > ./storage/democratic-csi-generic/proxy/env/storage-classes/$storageClassName-sc.yaml
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
