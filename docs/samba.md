
# Force user access to an SMB/samba share

```conf
force group	= 65534
force user = 65534
# or
force group	= nogroup
force user = nouser
```

Alternatively, you can force new files to inherit owner of the folder they are in:

```conf
inherit owner = yes
inherit permissions = yes
```

Also:

```conf
create mask = 777
directory mask = 777
# or
force create mode = 666
force directory mode = 777
```

Don't forget to restart samba service after changing the share settings.

References:
- https://man.freebsd.org/cgi/man.cgi?query=smb.conf
- https://www.thegeekdiary.com/how-to-force-user-group-ownership-of-files-on-a-samba-share/

# Per-share permissions

- Set `inherit owner = yes`
- Enable ALCs
- - When ALCs are disabled, folder group is not inherited for some reason
- Optionally set `force user = 65534`
- - You can set `force user = root` to allow access to everything
- Edit Share ACLs (don't confuse with dataset ACLs)
- - Set main entry to:
- - - SID: `S-1-1-0`
- - - Domain: empty
- - - Name: `Everyone`
- - - Type: `DENIED`
- - Set another entry to:
- - - Domain: `Group` or `User`
- - - Name: your desired group or user
- - - Type: `ALLOWED`
- Make sure your user has required auxiliary group
- Restart samba service to apply new settings

References:
- https://www.truenas.com/docs/scale/scaleuireference/shares/smbsharesscreens/#acl-entries-settings
