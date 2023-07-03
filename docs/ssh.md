
# Add user to `sudoers`

```bash
sudo adduser <username> sudo
```

# Disable password login

```bash
sudo nano /etc/ssh/sshd_config.d/disable_root_login.conf
```
```bash
PermitRootLogin no

ChallengeResponseAuthentication no

PasswordAuthentication no

UsePAM no

PermitRootLogin no

KbdInteractiveAuthentication no

AuthenticationMethods publickey
```

# Generate keys

```bash
ssh-keygen
cat public-key-file >> .ssh/authorized_keys
```

# Use key automatically

```bash
Host 10.0.2.105
   IdentityFile ~/.ssh/p40-key
```

# mount NFS

```bash
sudo mkdir /mnt/bulk
sudo mount -t nfs truenas.lan:/mnt/main/prox/nn /mnt/bulk
```
