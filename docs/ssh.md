
# SSH

This file contains useful commands for SSH setup both on server and on an client.

References:
- https://ivansalloum.com/comprehensive-linux-server-hardening-guide/

# Server: create new user for SSH access

```bash
username=
suffix=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 10)
# this command will prompt you for password
sudo adduser "$username-$suffix" --gecos ""

# enable user to use sudo
sudo adduser "$username-$suffix" sudo

# list all local users (custom ones should be at the end of the list)
cat /etc/passwd
```

If something goes wrong you can delete this user: `sudo userdel USERNAME`.

# Using SSH keys

Client: print your public key:

```bash
# the default key
public_key=~/.ssh/id_rsa.pub
echo $(cat "$public_key")

# generate a new one
output_file=~/.ssh/proxmox
# first check that key with this name doesn't exist yet
! ls -l "$output_file"*
ssh-keygen -b 4096 -f "$output_file"
echo $(cat "$output_file".pub)
```

Server: enable login with this key:

```bash
# move into your home directory
cd ~
# if you are root, specify user home directory manually
cd /home/user_name

mkdir -p ./.ssh
cat << EOF >> ./.ssh/authorized_keys
# content of the .pub file
EOF
```

Test client access with the private key:

```bash
# with the default key
ssh server
# using selected key
ssh -i "$output_file" username@server
```

Adjust SSH client config to use this key automatically:

```bash
#     template
# user-friendly name
server_name=
# IP or DNS to connect to the server
server_address=
# private key
server_key=
# user name on the server
server_username=

#     example
server_name=n100e1r2.pve.lan
server_address=192.168.255.2
server_key=~/.ssh/proxmox
server_username=myuser-qwertyuiop

mkdir -p ~/.ssh/config.d/
touch ~/.ssh/config
grep "^Include config.d/\*$" ~/.ssh/config || echo -e "Include config.d/*\n\n$(cat ~/.ssh/config)" > ~/.ssh/config
tee << EOF ~/.ssh/config.d/"$server_name".conf
Host $server_name
   HostName $server_address
   User $server_username
   Port 22
   IdentityFile $server_key
EOF

# test that you can connect
ssh $server_name
```

Additionally, you should be able to use SSH autocomplete with `$server_name`.

# Server: set up SSH

Lock down SSH: disable root login, disable password auth:

```bash
cat << EOF | sudo tee /etc/ssh/sshd_config.d/0-disable_password_auth.conf
PasswordAuthentication no
AuthenticationMethods publickey
# also a kind of password auth
ChallengeResponseAuthentication no
# also a kind of password auth
KbdInteractiveAuthentication no
# apparently, UsePAM may be insecure
UsePAM no
EOF
# some systems use root login, so you may want to skip disable_root_login
cat << EOF | sudo tee /etc/ssh/sshd_config.d/0-disable_root_login.conf
PermitRootLogin no
EOF
# force ssh to re-read its config
sudo systemctl restart ssh
```
