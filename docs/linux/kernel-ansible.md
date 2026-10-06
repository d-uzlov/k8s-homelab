
# download packages

```bash

kernel_url=https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-13-6.16/6.16.3-burstunlock0.zip
kernel_version=7.2.6-burstunlock0
kernel_archive=7.2.6-burstunlock0.zip
wget "$kernel_url" -O ./docs/linux/env/$kernel_archive
mkdir -p ./docs/linux/env/kernel-packages-$kernel_version/
unzip -d ./docs/linux/env/kernel-packages-$kernel_version/ ./docs/linux/env/$kernel_archive

```

# ansible inventory

You need to add your nodes nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
node-1:
  ansible_host: node-1.example.com
  ansible_python_interpreter: auto_silent
  # should match ./docs/linux/env/kernel-packages-$kernel_version/
  kernel_version: 7.1.8-burstunlock0
  # should match actual `uname -r` result
  kernel_uname: 7.1.8-burstunlock0-amd64
  # For Debian 12 + 6.12: `[ pahole, binutils, gcc-12, libdw1 ]`
  # For Debian 13 + 6.16: `[ pahole, binutils, gcc-14-for-host ]`
  # For Debian 13 + 6.19: `[ pahole, binutils, gcc-14-for-host, libconfig11, libnl-genl-3-200 ]`
  kernel_dependencies: [ pahole, binutils, gcc-14-for-host, libconfig11, libnl-genl-3-200 ]
  # There are no hard requirements for kernel commandline.
  # You can leave it empty if you don't need it.
  # You probably want to set `memhp_default_state=online`
  # when running a VM with memory hot-plug with kernel 6.16.
  kernel_grub_commandline: memhp_default_state=online
```

# deploy

```bash

ansible-inventory --graph modified_linux_kernel

ansible-playbook ./docs/linux/kernel-playbook.yaml
ansible-playbook ./docs/linux/kernel-playbook.yaml --limit node-name

```
