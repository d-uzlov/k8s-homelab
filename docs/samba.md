
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

# Server setup

References:
- https://phoenixnap.com/kb/ubuntu-samba
- https://confluence.jaytaala.com/display/TKB/Create+samba+share+writeable+by+all%2C+group%2C+or+only+a+user

```bash

sudo apt install -y samba
sudo apt install -y acl
# enable visibility in windows network explorer
# https://askubuntu.com/questions/661611/make-samba-share-visible-in-windows-network#comment2607665_1104414
sudo apt install -y wsdd

# https://gist.github.com/meetnick/fb5587d25d4174d7adbc8a1ded642d3c
curl -SsL https://gist.github.com/meetnick/fb5587d25d4174d7adbc8a1ded642d3c/raw/344576052b45afc7280dfc6aa226ca1b9ccd852f/add-external-conf-includes-samba-support |
  sudo tee /usr/local/sbin/smconf.sh
sudo chmod +x /usr/local/sbin/smconf.sh

sudo mkdir -p /etc/samba/smb.conf.d/

sudo nano /etc/samba/smb.conf.d/example.conf

# allow user to connect to samba
sudo smbpasswd -a $USER

# make sure that user that tries to access smb share actually has access to files
sudo groupadd samba-data
sudo useradd username -G samba-data
sudo chgrp samba-data --recursive /mnt/samba-shared/data
# also add set-gid flag
chmod g+s /media/share

# after you change shares update config and force samba to read it
sudo smconf.sh
sudo systemctl restart smbd

```

Example share config:

```conf

# windows will show this as share name
[my-samba-share]
comment = My Samba Share
path = /mnt/samba-shared/data
read only = no
writable = yes
browsable = yes
guest ok = no
; can use usernames or @group-name
; valid users = username1 username2 @samba-data @another-group
create mask = 0666
; force create mode = 0666
directory mask = 2777
force directory mode = 2777

force group	= samba-data
# force new files to inherit access control from folder
; inherit owner = yes
inherit permissions = yes

case sensitive = yes
preserve case = yes
short preserve case = yes

map archive = no
map system = no
map hidden = no

unix extensions = yes
acl allow execute always = yes
; can allow symlinks outside of share
allow insecure wide links = no

```

# SMB status

```bash

# show [partial] samba config
testparm
# print raw share config, but you need to process include directives yourself
cat /etc/samba/smb.conf
cat /etc/samba/smb.conf | grep include

# show shares (doesn't seem to work for generic shares)
sudo net usershare info --long '*'
sudo ls -la /var/lib/samba/usershares/

# show currently connected sessions
sudo smbstatus
sudo smbstatus --shares

```
