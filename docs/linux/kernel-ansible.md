
# download packages

```bash

kernel_url=https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-13-6.16/6.16.3-burstunlock0.zip
# kernel_version should match ansible inventory config
kernel_version=debian13-6.16-burst-unlock
wget "$kernel_url" -O ./docs/linux/env/6.16.3-burstunlock0.zip
mkdir -p ./docs/linux/env/kernel-packages-$kernel_version/
unzip -d ./docs/linux/env/kernel-packages-$kernel_version/ ./docs/linux/env/6.16.3-burstunlock0.zip

```

# deploy

Set `kernel_version` to matching folder name in `./docs/linux/env/kernel-packages-$kernel_version/`.
Set `kernel_uname` to expected `uname -r` value for each host.

Set `kernel_dependencies`:
- For Debian 12 + 6.12: `[ pahole, binutils, gcc-12, libdw1 ]`.
- For Debian 13 + 6.16: `[ pahole, binutils, gcc-14-for-host ]`.

Set `kernel_grub_commandline` to the value you need.
For 6.16 you probably want to enable automatic memory hot plug: `memhp_default_state=online`.

```bash

ansible-inventory --graph modified_linux_kernel

ansible-playbook ./docs/linux/kernel-playbook.yaml
ansible-playbook ./docs/linux/kernel-playbook.yaml --limit trixie-control-plane-1

```
