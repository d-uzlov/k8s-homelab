
# ZFS-on-Windows

References:
- https://github.com/openzfsonwindows/openzfs
- https://github.com/openzfsonwindows/openzfs/tree/windows/module/os/windows

ZFS on Windows requires you to use elevated terminal window.
If you try to use some of ZFS commands (`zfs`, `zdb`, `zpool`) in a non-elevated terminal,
it will spawn UAC prompt, open a new CMD window and immediately close it.
You will not be able to inspect the output.

# Create from file

```powershell
fsutil.exe file createnew C:\poolfile.bin 200000000
zpool.exe create tank \\?\C:\poolfile.bin
```

# Create from drive

```powershell
# Find paths to available drives
wmic.exe diskdrive list brief

# create a root dataset which will not be mounted
zpool.exe create `
    -o ashift=12 `
    -O casesensitivity=insensitive `
    -O compression=lz4 `
    -O atime=off `
    -O encryption=off `
    -O dedup=off `
    -O recordsize=128k `
    -O checksum=edonr `
    -O xattr=sa `
    -O driveletter=- `
    -O mountpoint=none `
    tank `
    mirror PHYSICALDRIVE0 PHYSICALDRIVE1

# created visible datasets
zfs.exe create -o driveletter=L -o mountpoint=/zfs/tank/local tank/local
zfs.exe create -o driveletter=M -o mountpoint=/zfs/tank/media tank/media
zfs.exe create -o driveletter=G -o mountpoint=/zfs/tank/games tank/games

# if something doesn't mount
zfs.exe unmount -a
zfs.exe mount -a
# also don't forget to refresh the list of drives
```

# ZVOLs

```powershell
# thick volume
zfs.exe create -V 2g tank/test-zvol
# sparse volume
zfs.exe create -s -V 2g tank/test-zvol
```

ZVOLs will appear in the disk management utility
as an empty drive of specified capacity.

# Limit max ARC size

- Open regedit
- Go to `Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\OpenZFS\zfs_arc`
- Set `zfs_arc_max` in bytes
- - For example:
- - 4294967296 is 4 GB

# Mount on startup

- Search `scheduler` in Start menu
- Open Task Scheduler
- Run Actions -> Create New Basic Task
- Specify command `zpool.exe`, options `import tank`
- Set trigger "At system Startup"
- Set account SYSTEM
- Set Run with highest privileges
