
# ZFS

See here for ZFs installation instructions: [cockpit docs](../../../docs/cockpit/cockpit.md#zfs)

# SSH setup

Democratic CSI needs access to the following  commands:
- `zfs`
- `zpool`
- ¿ `chroot` ?

You either need to allow these commands,
or allow passwordless sudo, like this guide does.

User doesn't need to have password, you only need SSH access.

Generate SSH keys locally:

```bash

ssh-keygen -t ed25519 -C "democratic-csi" -N '' -f ./storage/democratic-csi-generic/proxy/env/ssh-key
ssh-keygen -b 4096 -f ./storage/democratic-csi-generic/proxy/env/ssh-key

# after you create user on the server,
# place contents of .pub file into ~/.ssh/authorized_keys
cat ./storage/democratic-csi-generic/proxy/env/ssh-key.pub

```

Run on the server to set up SSH access:

```bash

sudo useradd --create-home --shell /bin/bash democratic-csi
sudo adduser democratic-csi sudo

echo "democratic-csi ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/democratic-csi

sudo su - democratic-csi
mkdir -p ~/.ssh/
# paste ./storage/democratic-csi-generic/proxy/env/ssh-key.pub contents into authorized_keys
nano ~/.ssh/authorized_keys
touch ~/.hushlogin

```
