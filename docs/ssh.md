
# Disable password login

sudo nano /etc/ssh/sshd_config.d/disable_root_login.conf
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

ssh-keygen
cat publick-key-file >> .ssh/authorized_keys

# Use key automatically

```bash
Host 10.0.2.105
   IdentityFile ~/.ssh/p40-key
```
