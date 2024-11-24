
# Proxmox containers

# Init container

```bash
apt update && apt full-upgrade -y && apt install -y sudo
sudo apt install -y curl lsb-release htop net-tools
```

Optionally:
- Create your user: [instructions](../linux-users.md#create-new-user)
- Copy SSH public key: `ssh-copy-id container.ip.address` (run on the main PC)
- Forbid password SSH access: [SSH cheat sheet](../ssh.md#server-set-up-ssh)
- Set up Bash: [Bash cheat sheet](../bash-setup.md)

# Docker

```bash
curl https://get.docker.com | bash
# enable using docker without sudo
sudo usermod -aG docker $USER
newgrp docker
# check that everything is working
docker run hello-world
```
