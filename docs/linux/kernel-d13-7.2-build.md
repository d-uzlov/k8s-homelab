
# building Debian 13 kernel (6.16 from backports)

Build script fails in a VM with 64 GB disk. It also fails with a 96 GB disk.

```bash

sudo apt update

sudo apt-get install -y build-essential
apt-cache search kernel-wedge
apt-cache madison kernel-wedge
sudo apt-get install -y kernel-wedge=2.106
sudo apt-get build-dep -y linux

sudo apt install zip

sudo apt-get install -y devscripts

mkdir ~/building-linux/

# apt-get source linux
git clone -b debian/7.2/trixie-backports --single-branch https://salsa.debian.org/kernel-team/linux.git ~/building-linux/linux-trixie-7.2

cd ~/building-linux/
rm *.deb *.udeb ${patch_version}-burstunlock0.zip *.buildinfo *.changes

cd ~/building-linux/linux-trixie-7.2/

# check out current patch version
dch --edit
patch_version=7.2.6

# Version format need to be exactly this:
# - '${patch_version}-burstunlock0-0' is the kernel version
# - `${patch_version}-burstunlock0-0~bpo13+1` is full package version, but package suffix '~bpo13+1' will not be shown in `uname -r` and similar tools
# - if suffix is not before the first ~, it will be included in the package but not in kernel version
# - if suffix text does not have '0' on the end, it will fail debian validating regexp
# - if suffix does not have -0 after the text part, it will fail ANOTHER validating regexp
# - if suffix uses capital letters, it will fail ONE ANOTHER validating regexp
# - '~bpo13+1' is included to document the upstream version, it can probably be omitted
# - - (though, it may cause some other validation errors, I didn't check)
# distribution needs to be set, or else debian will refuse to save any version info at all
dch -v ${patch_version}-burstunlock0-0~bpo13+1 --distribution cgroup-burst-unlock
# add '* enable unlimited cfs cpu burst' as release note

curl -fL https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-${patch_version}.tar.gz > ~/building-linux/linux_${patch_version}.orig.tar.xz

mkdir -p ~/building-linux/orig/
tar -C ~/building-linux/orig/ -xaf ~/building-linux/linux_${patch_version}.orig.tar.xz

debian/rules debian/control

# patch for 6.19 still works for 7.2
curl -fsSL https://raw.githubusercontent.com/d-uzlov/k8s-homelab/refs/heads/master/docs/linux/kernel-d13-6.19-burst-unlock.patch > ./debian/patches/features/all/cgroup-burst.patch
echo features/all/cgroup-burst.patch >> debian/patches/series

sed -i 's/enable_signed = true/enable_signed = false/' debian/config/amd64/defines.toml

git clean -dfX ./debian
fakeroot debian/rules clean
debian/rules DIR_ORIG=~/building-linux/orig/linux-${patch_version}/ TAR_ORIG=~/building-linux/linux_${patch_version}.orig.tar.xz orig

export MAKEFLAGS=-j$(nproc)
export DEB_BUILD_PROFILES='nodoc pkg.linux.nokerneldbg pkg.linux.nokerneldbginfo'
export DEB_BUILD_OPTIONS="nodoc terse"

dpkg-buildpackage --build=any,all --no-pre-clean --no-sign > ./build-$(date +%Y%m%d.%H%M).log
# dpkg-buildpackage --build=any --no-pre-clean --no-sign > ./build-$(date +%Y%m%d.%H%M).log
ll ~/building-linux/linux-trixie-7.2/build-*

# when changing version format, you can run a smaller target to check resulting packages
# make -f debian/rules.gen binary-indep
# make -f debian/rules.gen binary-arch_amd64_none_amd64
# make -f debian/rules.real binary_headers-common

# let's create an archive from packages created by the build process
cd ~/building-linux/
rm ~/building-linux/*.udeb ~/building-linux/${patch_version}-burstunlock0.zip

zip --must-match -0 ${patch_version}-burstunlock0.zip \
  bpftool_7.8.0+${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  bpftool-dbgsym_7.8.0+${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  libcpupower1_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  libcpupower1-dbgsym_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  libcpupower-dev_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-base-${patch_version}-burstunlock0-amd64_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-binary-${patch_version}-burstunlock0-amd64_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-bpf-dev_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-config-7.2_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-cpupower_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-cpupower-dbgsym_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-headers-${patch_version}-burstunlock0-amd64_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-headers-${patch_version}-burstunlock0-common_${patch_version}-burstunlock0-0~bpo13+1_all.deb \
  linux-image-${patch_version}-burstunlock0-amd64_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-kbuild-${patch_version}-burstunlock0_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-libc-dev_${patch_version}-burstunlock0-0~bpo13+1_all.deb \
  linux-misc-tools_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-misc-tools-dbgsym_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-modules-${patch_version}-burstunlock0-amd64_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-perf_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-perf-dbgsym_${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  linux-source-7.2_${patch_version}-burstunlock0-0~bpo13+1_all.deb \
  linux-source_${patch_version}-burstunlock0-0~bpo13+1_all.deb \
  usbip_2.0+${patch_version}-burstunlock0-0~bpo13+1_amd64.deb \
  usbip-dbgsym_2.0+${patch_version}-burstunlock0-0~bpo13+1_amd64.deb

```

When building kernel on a remove machine copy resulting zip files to local machine:

```bash

mkdir -p ./docs/linux/env/

patch_version=7.2.6

rm -f ./docs/linux/env/${patch_version}-burstunlock0.zip

remote=d13-build-7-1.guest.lan
scp $remote:~/building-linux/${patch_version}-burstunlock0.zip ./docs/linux/env/

test_remote=d13-test-kernel-7-1.guest.lan
scp ./docs/linux/env/${patch_version}-burstunlock0.zip $test_remote:~/linux-kernel/${patch_version}-burstunlock0.zip

ssh $test_remote

# on the test remote
patch_version=7.2.6
mkdir -p ~/linux-kernel/linux-${patch_version}-burstunlock0/
unzip -d ~/linux-kernel/linux-${patch_version}-burstunlock0/ ~/linux-kernel/${patch_version}-burstunlock0.zip

# libnl-genl-3-200 is for linux-cpupower
# gcc-14-for-host is for linux-headers
# pahole is for linux-kbuild
# libconfig11 is for linux-misc-tools
# libbabeltrace1 libdebuginfod1t64 libdw1t64 libopencsd1 libtraceevent1 is for linux-perf
# binutils is for linux-source
# usb.ids is for usbip
# linux-base is for linux-image-7.2.6
sudo apt install -y libnl-genl-3-200 gcc-14-for-host pahole libconfig11 libbabeltrace1 libdebuginfod1t64 libdw1t64 libopencsd1 libtraceevent1 binutils usb.ids linux-base=4.17~bpo13+1

sudo dpkg -i ~/linux-kernel/linux-${patch_version}-burstunlock0/*.deb

# remove everything
sudo dpkg --list | grep ${patch_version}-burstunlock0 | awk '{ print $2 }' | xargs sudo dpkg -P

```
