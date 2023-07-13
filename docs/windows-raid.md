
# Windows RAID

This file describes the state of RAID and similar technologies on Windows in 2023.

This file focuses on mirrors, or RAID 1.

# Storage spaces

Doesn't have direct support for mirrors but has something similar.
You can configure it to maintain N copies of data
and make sure that these copies are placed on different drives.

Looks very slow and unreliable.

There are a lot of horror stories about Storage spaces:

- https://serverfault.com/questions/864633/is-there-a-reason-to-use-a-storage-pool-instead-of-creating-a-raid-5-volume#comment1160136_867305
- - > last year I bought 4 hdd's for raid-5 in storage spaces,
    > after installation I wanted to test what would happen if one drive failed
    > so i pulled out 1 of the sata cables.
    > I got a error message all well and good, but when i tried to remount the drive,
    > it wasn't picked up automaticly and i could not remove the failed drive from storage spaces.
    > A fresh windows install was the only thing that worked
- - > the write speeds were very inconsistant, dropping to 0 mb/sec
- https://www.reddit.com/r/DataHoarder/comments/132egn5/storage_spaces_nightmare_im_desparate/
- - > Raid was showing "Error" state, one of the drives was showind "OK" state,
    > and another drive "Warning" state.
    > The logical raid volume was no longer showing, neither in explorer nor disk manager.
- - > What I have now is:
    > - Two-way mirror Storage Spaces raid in "error" state ("check physical drives section")
    > - - One old drive in "OK" state, with all the data as I understand it.
    > - - One old drive in "Warning / Preparing for removal" state, S.M.A.R.T. showing a few reallocated sectors. I marked it as "Retired" previously via powershell cmdlet.
    > - - One new drive in "Warning / Retired; add a drive then remove this drive" state, also marked as retired by me. The drive is wiped clean after being physically removed.
    > - Get-StorageJob shows Storage pool-Rebalance in Shutting Down state.

There are no recovery tools:
- https://www.reddit.com/r/DataHoarder/comments/aug23q/comment/hl0zrdk/

# Disk management

Relatively easy to use.

Very unlikely to loose your data.

Deprecated.

If a mirror breaks even for a second, it's impossible to restore it, you have to re-create it.

For example, if you pull out a drive that contains a mirrored volume,
and then immediately reconnect it,
mirror status becomes "Failed Redundancy",
and you need to remove the old mirror and create a new one,
which in the process will resync the whole disk content from scratch.

While you are re-creating the mirror, your data will be completely unprotected.

If any unsafe shutdown happen, it will also likely require resyncing.
For example: BSOD, power loss, hard reboot.

Opinions (there doesn't seem to be too much negativity, unlike Storage Spaces):

- https://learn.microsoft.com/en-us/answers/questions/340485/storage-spaces-vs-disk-management-mirroring-resync
- - > it has a nasty habit of resyncing every time I make slight alterations to the server
    > (just changing a fan, or removing a wifi card, will make it resync).
    > A resync takes almost a full day, is quite noisy and noticeably reduces performance
- https://www.reddit.com/r/DataHoarder/comments/uy0y1z/comment/ia1ftr6/
- - > Hw raid will resync on power loss without a battery backup on the card too

It's possible to use this for the boot drive (all these links describe the same thing):
- https://www.wintips.org/how-to-mirror-boot-hard-drive-on-windows-10-legacy-or-uefi/
- https://docs.hetzner.com/robot/dedicated-server/raid/windows-server-software-raid/

# StableBit DrivePool

Not a RAID.

Works on top of a filesystem (maybe NTFS-specific? I'm not sure).

You create filesystem on several individual disks and add them to the pool.

The app creates a virtual disk, which, when you write something to it,
distributes the files among different disks.

The main purpose of the app is to span files across disks,
so you don't have to manage free space manually.

But the program also have the ability to duplicate data on different disks,
making it similar to mirror RAID.

It's unclear how well it would work with a boot drive
or with general purpose drive, like Steam library.

# SnapRAID

Not a RAID.

Creates file checksums to "protect" against bit-rot, and allegedly some sort of parity,
to protect against drive failures.

Keeps parity on a separate drive, like RAID 4.

Can work with drives of different sizes.

Apparently it works offline.
For example, run it once a day to calculate and save checksums and parity.

I don't think it makes sense for a mirror.

# Copying files

You can simply copy files from one disk to another
using utils like `robocopy` or `rsync`.
