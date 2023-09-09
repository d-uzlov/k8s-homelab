
# Storage

This folder contains deployments for connecting persistent storage to pods

There are several ways to access the same storage.
It is expected that you choose only some of them,
you don't need to deploy everything.

# Storage classes

Generally PVCs create namespace-specific share,
and all data is deleted whenever you delete PVC.

If not stated otherwise, different storage classes of the same type
are supposed to just point to different servers, or different shares on the same server.

- NFS
- - NFS-CSI
- - - [bulk](./nfs-csi/storage-classes/bulk/readme.md)
- - - [bulk-persist](./nfs-csi/storage-classes/bulk-persist/readme.md)
- - - - Data is not deleted when you delete PVC
- - - [fast](./nfs-csi/storage-classes/fast/readme.md)
- - - [shared](./nfs-csi/storage-classes/shared/readme.md)
- - - - PVC with the same name will see the same data regardless of namespace
- - - - Data is not deleted when you delete PVC
- - Democratic CSI
- - - [bulk](./democratic-csi/nfs/bulk/readme.md)
- - - [fast](./democratic-csi/nfs/fast/readme.md)
- iSCSI
- - Democratic CSI
- - - [block](./democratic-csi/iscsi/block/readme.md)
- SMB
- - _SMB is incompatible with Linux permission system,_
    _file permissions can be emulated_
    _but you are forced to use the same user ID everywhere_
- - SMB-CSI
- - - [bulk](./smb-csi/storage-classes/bulk/readme.md)
- - - [fast](./smb-csi/storage-classes/fast/readme.md)
