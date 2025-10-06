
# install burst-unlock-patched kernel 6.12 on debian 12

Note that this is specific to Debian 12.

# manual installation

```bash

# check if this kernel is already installed
sudo dpkg --list | grep 6.12.22-burstunlock

mkdir linux-6.12.22-burstunlock0
cd linux-6.12.22-burstunlock0

wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-6.12/6.12.22-burstunlock0.zip
mkdir no-debug
unzip -d no-debug 6.12.22-burstunlock0.zip

sudo apt install -y libdw1 pahole gcc-12 binutils

sudo dpkg -i ./no-debug/*.deb

# optionally also install debug packages
wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-6.12/6.12.22-burstunlock0-debug.zip
mkdir debug
unzip -d debug 6.12.22-burstunlock0-debug.zip

sudo apt install -y libbabeltrace1 libdebuginfod1 libopencsd1 libtraceevent1 libunwind8 libpython3.11

sudo dpkg -i ./debug/*.deb

# list installed packages
sudo dpkg --list | grep 6.12.22-burstunlock0

```

If you want to remove this kernel:

```bash

sudo dpkg --list | grep 6.12.22-burstunlock0 | awk '{ print $2 }' | xargs sudo dpkg -P

```
