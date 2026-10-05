
# building Debian 13 kernel (6.16 from backports)

Build script fails in a VM with 64 GB disk. It also fails with a 96 GB disk.

```bash

sudo apt update
apt-cache search linux-image | grep linux-image | grep "\+deb" | grep -v -e "-rt-" -e "-cloud-" | grep unsigned
# sudo apt install linux-image-6.18.15+deb13-amd64-unsigned

sudo apt-get install -y build-essential
apt-cache search kernel-wedge
apt-cache madison kernel-wedge
sudo apt-get install -y kernel-wedge=2.106
sudo apt-get build-dep -y linux

sudo apt install zip

sudo apt-get install -y devscripts

mkdir ~/building-linux/

# apt-get source linux
git clone -b debian/6.19/trixie-backports --single-branch https://salsa.debian.org/kernel-team/linux.git ~/building-linux/linux-trixie-6.19

cd ~/building-linux/
rm *.deb *.udeb 6.19.14-burstunlock0.zip *.buildinfo *.changes

cd ~/building-linux/linux-trixie-6.19/

# check out current patch version
dch --edit
# at the moment of writing this script debian 6.19 is using 6.19.14 patch
# update commands to use your patch version before running

# Version format need to be exactly this:
# - '6.19.14-burstunlock0-0' is the kernel version
# - `6.19.14-burstunlock0-0~bpo13+1` is full package version, but package suffix '~bpo13+1' will not be shown in `uname -r` and similar tools
# - if suffix is not before the first ~, it will be included in the package but not in kernel version
# - if suffix text does not have '0' on the end, it will fail debian validating regexp
# - if suffix does not have -0 after the text part, it will fail ANOTHER validating regexp
# - if suffix uses capital letters, it will fail ONE ANOTHER validating regexp
# - '~bpo13+1' is included to document the upstream version, it can probably be omitted
# - - (though, it may cause some other validation errors, I didn't check)
# distribution needs to be set, or else debian will refuse to save any version info at all
dch -v 6.19.14-burstunlock0-0~bpo13+1 --distribution cgroup-burst-unlock
# add '* enable unlimited cfs cpu burst' as release note

curl -fsSL https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-6.19.14.tar.gz > ~/building-linux/linux_6.19.14.orig.tar.xz

mkdir -p ~/building-linux/orig/
tar -C ~/building-linux/orig/ -xaf ~/building-linux/linux_6.19.14.orig.tar.xz

debian/rules debian/control

curl -fsSL https://raw.githubusercontent.com/d-uzlov/k8s-homelab/refs/heads/master/docs/linux/kernel-d13-6.19-burst-unlock.patch > ./debian/patches/features/all/cgroup-burst.patch
echo features/all/cgroup-burst.patch >> debian/patches/series

sed -i 's/enable_signed = true/enable_signed = false/' debian/config/amd64/defines.toml

git clean -dfX ./debian
fakeroot debian/rules clean
debian/rules DIR_ORIG=~/building-linux/orig/linux-6.19.14/ TAR_ORIG=~/building-linux/linux_6.19.14.orig.tar.xz orig

export MAKEFLAGS=-j$(nproc)
# debug info is required for some stuff to work, for example BPF CO-RE, even without installing debug packages
export DEB_BUILD_PROFILES='nodoc pkg.linux.nokerneldbg pkg.linux.nokerneldbginfo'
# export DEB_BUILD_PROFILES='nodoc'
export DEB_BUILD_OPTIONS="nodoc terse"

dpkg-buildpackage --build=any,all --no-pre-clean --no-sign > ./build-$(date +%Y%m%d.%H%M).log
# dpkg-buildpackage --build=any --no-pre-clean --no-sign > ./build-$(date +%Y%m%d.%H%M).log
ll ~/building-linux/linux-trixie-6.19/build-*

# when changing version format, you can run a smaller target to check resulting packages
# make -f debian/rules.gen binary-indep
# make -f debian/rules.gen binary-arch_amd64_none_amd64
# make -f debian/rules.real binary_headers-common

# let's create an archive from packages created by the build process
cd ~/building-linux/
rm ~/building-linux/*.udeb ~/building-linux/6.19.14-burstunlock0.zip

zip -0 6.19.14-burstunlock0.zip \
  bpftool_7.7.0+6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  bpftool-dbgsym_7.7.0+6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  libcpupower1_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  libcpupower1-dbgsym_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-base-6.19.14-burstunlock0-amd64_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-binary-6.19.14-burstunlock0-amd64_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-bpf-dev_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-config-6.19_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-cpupower_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-cpupower-dbgsym_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-headers-6.19.14-burstunlock0-amd64_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-headers-6.19.14-burstunlock0-common_6.19.14-burstunlock0-0~bpo13+1_all.deb \
  linux-image-6.19.14-burstunlock0-amd64_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-kbuild-6.19.14-burstunlock0_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-libc-dev_6.19.14-burstunlock0-0~bpo13+1_all.deb \
  linux-misc-tools_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-misc-tools-dbgsym_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-modules-6.19.14-burstunlock0-amd64_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-perf_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-perf-dbgsym_6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  linux-source-6.19_6.19.14-burstunlock0-0~bpo13+1_all.deb \
  linux-source_6.19.14-burstunlock0-0~bpo13+1_all.deb \
  usbip_2.0+6.19.14-burstunlock0-0~bpo13+1_amd64.deb \
  usbip-dbgsym_2.0+6.19.14-burstunlock0-0~bpo13+1_amd64.deb

```

When building kernel on a remove machine copy resulting zip files to local machine:

```bash

mkdir -p ./docs/linux/env/

rm -f ./docs/linux/env/6.19.14-burstunlock0.zip

remote=d13-build-6-19.guest.lan
scp $remote:~/building-linux/6.19.14-burstunlock0.zip ./docs/linux/env/

test_remote=d13-test-kernel.guest.lan
scp ./docs/linux/env/6.19.14-burstunlock0.zip $test_remote:~/linux-kernel/6.19.14-burstunlock0.zip

```
