
# install burst-unlock-patched kernel 6.16 on debian 12

Note that this is specific to Debian 13.
Installation on Debian 12 is not covered here.

# manual installation

SSH into a node and run the commands:

```bash

# check if this kernel is already installed
sudo dpkg --list | grep 6.16.3-burstunlock

sudo apt install -y pahole binutils gcc-14-for-host  --no-install-recommends --no-install-suggests

mkdir -p ~/linux-kernel/linux-6.16.3-burstunlock0/main/

wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-13-6.16/6.16.3-burstunlock0.zip -O ~/linux-kernel/6.16.3-burstunlock0.zip
unzip -d ~/linux-kernel/linux-6.16.3-burstunlock0/main/ ~/linux-kernel/6.16.3-burstunlock0.zip

sudo dpkg -i ~/linux-kernel/linux-6.16.3-burstunlock0/main/*.deb

# list installed packages
sudo dpkg --list | grep 6.16.3-burstunlock0

# optionally also install debug packages
wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-13-6.16/6.16.3-burstunlock0-debug.zip -O ~/linux-kernel/6.16.3-burstunlock0-debug.zip
mkdir -p ~/linux-kernel/linux-6.16.3-burstunlock0/debug/
unzip -d ~/linux-kernel/linux-6.16.3-burstunlock0/debug/ ~/linux-kernel/6.16.3-burstunlock0-debug.zip

sudo apt install -y libbabeltrace1 libdebuginfod1t64 libopencsd1 libtraceevent1 linux-perf

sudo dpkg -i ~/linux-kernel/linux-6.16.3-burstunlock0/debug/*.deb

```

If you want to remove this kernel:

```bash

sudo dpkg --list | grep 6.16.3-burstunlock0 | awk '{ print $2 }' | xargs sudo dpkg -P

```

Check out [kernel-ansible.md](./kernel-ansible.md) for installing via ansible.
