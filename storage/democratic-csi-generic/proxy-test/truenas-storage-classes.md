
# Environment setup

- Create Truenas Scale instance
- Create dataset for NFS shares
- - Make sure that you don't share this dataset or any of its parent datasets via nfs
- - If there is an common share you will get an error like this:
- - `<pvc dataset path> is a subtree of <parent NFS share path> and already exports this dataset for 'everybody'`
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Create at least one NFS share and enable NFS service
- - It seems like it's not possible to enable the service if you don't have shares yet

# NFS

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/
mkdir -p ./storage/democratic-csi-generic/proxy/env/storage-classes/

storageClassName=test-nvme-sc
connectionName=$storageClassName
serverAddress=test.example.com
api_key=1-qwertyuiiopasdfghjklzxcvbnm
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
# doesn't need to be a real dataset if you don't want to use detached snapshots
snapshotDataset=invalid

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName.yaml
driver: freenas-api-nfs

zfs:
  # main and snapshot datasets should not be nested in each other
  datasetParentName: $mainDataset
  detachedSnapshotsDatasetParentName: $snapshotDataset

nfs:
  shareHost: $serverAddress

httpConnection:
  protocol: http
  host: $serverAddress
  port: 80
  apiKey: $api_key
  allowInsecure: true
  apiVersion: 2
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

# iSCSI

- Create Truenas Scale instance
- Enable iSCSI service
- Create iSCSI portal (simple case: no auth, listen on 0.0.0.0)
- Create initiator group (simple case: check "Allow all initiators")
- Go to `Top Bar -> Settings -> API Keys` and create a new key
- Create dataset for iSCSI volumes

```bash

mkdir -p ./storage/democratic-csi-generic/proxy/env/connections/
mkdir -p ./storage/democratic-csi-generic/proxy/env/storage-classes/

storageClassName=test-nvme-sc
connectionName=$storageClassName
serverAddress=test.example.com
api_key=1-qwertyuiiopasdfghjklzxcvbnm
# main and snapshot datasets must not be nested in each other
mainDataset=tank/k8s
# snapshotDataset=tank/k8s-snap
# doesn't need to be a real dataset if you don't want to use detached snapshots
snapshotDataset=invalid

iqnBaseName=iqn.2025-01.com.example:location:nas-nickname
iqnPrefix=k8s-cluster-nickname:

 cat << EOF > ./storage/democratic-csi-generic/proxy/env/connections/$connectionName.yaml
driver: freenas-api-iscsi

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

httpConnection:
  protocol: http
  host: $serverAddress
  port: 80
  apiKey: $api_key
  allowInsecure: true
  apiVersion: 2
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
