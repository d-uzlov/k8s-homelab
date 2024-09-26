
# Proxmox containers

# Init container

```bash
apt update
apt full-upgrade -y
apt install -y sudo

username=
sudo useradd -m "$username"
sudo passwd "$username"
# sudo adduser "$username" sudo
echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$username

chsh -s /bin/bash

sudo apt install -y curl lsb-release htop
```

Optionally:
- Copy SSH public key: `ssh-copy-id container.ip.address` (run on the main PC)
- Forbid password SSH access: [SSH cheat sheet](../ssh.md#server-set-up-ssh)
- Set up Bash: [Bah cheat sheet](../bash.md)
