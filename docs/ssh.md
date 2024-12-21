
# SSH

This file contains useful commands for SSH setup both on server and on an client.

References:
- https://ivansalloum.com/comprehensive-linux-server-hardening-guide/

# Generate new SSH key

If you don't have a key, or if you want to use a separate key for something.

```bash
# generate a new one
output_file=~/.ssh/new-key
# avoid rewriting already existing keys
! ls -l "$output_file" || ( echo file exists; exit 1; )
! ls -l "$output_file".pub || ( echo file exists; exit 1; )

# to generate the default key
# ssh-keygen -b 4096
ssh-keygen -b 4096 -f "$output_file"
```

# Allow login with your SSH key

Client: print your public key.

```bash
public_key=~/.ssh/id_rsa.pub
echo $(cat "$public_key")
# change the path if you don't want to use the default id_rsa key
```

Server: enable login with this key.
You must be logged in as your user.

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# insert public key into the file
```

Test client access with the private key.

```bash
# with the default key
ssh server.address
# using a selected key
ssh -i "$output_file" username@server
```

# Add SSH config for a certain server

Set a name for a server and override some defaults:
- You can redirect connection to a different IP or domain
- Set custom key instead of the default one
- Set different username

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
grep "^Include config.d/\*$" ~/.ssh/config || echo -e "Include config.d/*\n\n$(cat ~/.ssh/config)" >> ~/.ssh/config
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
sudo systemctl restart sshd
```

# Enable root login

In cases when you need it.

```bash
cat << EOF | tee /etc/ssh/sshd_config.d/1-enable_root_login.conf
PermitRootLogin yes
EOF
sudo systemctl restart sshd
```

# SSH port forwarding

```bash
ssh -L local_port:forwarded_ip:forwarded_port server-address
# by default ssh client listens on localhost, but you can change it
ssh -L local_address:local_port:forwarded_ip:forwarded_port server-address

# example: remote machine has access
# to an HTTP server in its LAN at address 192.168.1.1,
# you want to access it via localhost:8080
ssh -L 8080:192.168.1.1:80 server-address
# example: remote server has a program listening on localhost
# you want to allow everyone in your local LAN to access it via the ssh client machine
ssh -L 10.1.2.3:2000:127.0.0.1:2000 server-address
```
