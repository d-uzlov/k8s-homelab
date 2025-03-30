
# Snapshot-controller

References:
- https://github.com/kubernetes-csi/external-snapshotter?tab=readme-ov-file#usage

# Update

```bash

rm -r ./storage/snapshot-controller/crd/
mkdir -p ./storage/snapshot-controller/crd/

(
cd ./storage/snapshot-controller/crd/

release_tag=release-8.2

crd_files=(
  snapshot.storage.k8s.io_volumesnapshotclasses.yaml
  snapshot.storage.k8s.io_volumesnapshotcontents.yaml
  snapshot.storage.k8s.io_volumesnapshots.yaml
  groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml
  groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml
  groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml
)

for file in ${crd_files[@]}; do
  wget -O "${file}" https://github.com/kubernetes-csi/external-snapshotter/raw/refs/heads/$release_tag/client/config/crd/$file
done
)

(
cd ./storage/snapshot-controller/controller/
rm rbac-snapshot-controller.yaml setup-snapshot-controller.yaml
wget https://github.com/kubernetes-csi/external-snapshotter/raw/refs/heads/release-8.2/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
# wget https://github.com/kubernetes-csi/external-snapshotter/raw/refs/heads/release-8.2/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
sed -i 's/kube-system/pv-snapshots/' rbac-snapshot-controller.yaml setup-snapshot-controller.yaml
)

```

Change the image version in the controller deployment manually.

# Deploy

```bash

kl apply -f ./storage/snapshot-controller/crd/ --server-side

kl create ns pv-snapshots
kl label ns pv-snapshots pod-security.kubernetes.io/enforce=baseline

kl -n pv-snapshots apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-snapshots apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/snapshot-controller/controller/
kl -n pv-snapshots get pod -o wide

kl -n pv-snapshots logs deployments/snapshot-controller > ./snapshot-controller.log

# Sometimes "vs" (short name for VolumeSnapshot),
# is already used for different resources in your cluster.
# You may need to change resource short names.
# https://github.com/kubernetes/kubernetes/issues/123514
kl api-resources | grep vs

```

# Cleanup

```bash
kl delete -k ./storage/snapshot-controller/controller/
kl delete ns pv-snapshots
```

# Snapshot test

```bash

kl get pvc

# set to existing PVC
pvcName=
# choose any
snapshotName=
volumeSnapshotClassName=

# create snapshot
kl apply -f - << EOF
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: $snapshotName
spec:
  volumeSnapshotClassName: $volumeSnapshotClassName
  source:
    persistentVolumeClaimName: $pvcName
EOF

kl get vss
kl describe vss test-snap-tulip-test
kl get vsc

# =======
# create volume with snapshot content
# =======

# storage class name usually needs to match storage class of the original volume
# provisioner driver MUST be the same
kl get sc
storageClassName=

restoredPvcName=

kl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $restoredPvcName
spec:
  storageClassName: $storageClassName
  dataSource:
    apiGroup: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: $snapshotName
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

kl get pvc
kl describe pvc $restoredPvcName

```
