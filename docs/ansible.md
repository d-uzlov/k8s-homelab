
# ansible

# install

```bash

# sudo apt install ansible
# apt version is outdated
pipx install --include-deps ansible
pipx inject --include-apps ansible argcomplete

pipx upgrade --include-injected ansible

```

# cleanup

```bash

pipx uninstall ansible
ll ~/.local/pipx/venvs/ansible

```

# test

```bash

inventory_file=

# example of an inventory file
 cat << EOF > $inventory_file
---
nas:
  hosts:
    rose:
      ansible_host: nas-rose.k8s.lan
      ansible_python_interpreter: auto_silent

proxmox:
  hosts:
    pve1:
      ansible_host: pve1.example.org
      ansible_python_interpreter: auto_silent

cadvisor:
  children:
    nas:
    proxmox:
EOF

 cat << EOF > ~/.ansible.cfg
[defaults]
inventory = $inventory_file
EOF

ansible-inventory --list
ansible-inventory --graph

ansible nas -m ping
ansible generic -m ping

```
