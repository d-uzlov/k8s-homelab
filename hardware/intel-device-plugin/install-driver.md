
# Transcoding

References:
- https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new
- https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html
- https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/
- https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/

# host

```bash
apt install -y build-* dkms git
apt install -y pve-headers-6.2.16-12-pve

git clone https://github.com/strongtz/i915-sriov-dkms.git
nano i915-sriov-dkms/dkms.conf
# set package name to i915-sriov-dkms
# set version to 6.1
mv i915-sriov-dkms /usr/src/i915-sriov-dkms-6.1

dkms install -m i915-sriov-dkms -v 6.1 --force
# this can take a long time
dkms status

nano /etc/kernel/cmdline
# add: i915.enable_guc=3 i915.max_vfs=7
proxmox-boot-tool refresh
# if you are having issues, you could also try this: update-initramfs -u -k all
reboot now

# you can try to install a different kernel if you want to
proxmox-boot-tool kernel list
proxmox-boot-tool kernel pin 6.2.16-12-pve
```

```bash
# enable automatically after reboot
echo "devices/pci0000:00/0000:00:02.0/sriov_numvfs = 1" > /etc/sysfs.conf
# or enable for current session
echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs"
# you can set up to `i915.max_vfs` virtual devices
```

# guest

```bash
sudo apt install -y build-* dkms git

git clone https://github.com/strongtz/i915-sriov-dkms.git
nano i915-sriov-dkms/dkms.conf
# set package name to i915-sriov-dkms
# set version to 6.1
sudo mv i915-sriov-dkms /usr/src/i915-sriov-dkms-6.1

# this can take a long time
sudo dkms install -m i915-sriov-dkms -v 6.1 --force
# dkms may fail with an error describing which modules you need to additionally install
sudo dkms status

sudo nano /etc/default/grub
# add i915.enable_guc=3
sudo update-grub
sudo update-initramfs -u

sudo reboot
```

After reboot check that driver successfully loaded:
```bash
sudo dmesg | grep i915
# dmesg may show that some symbols are missing
# this is a known issue:
#   https://github.com/strongtz/i915-sriov-dkms/issues/55#issuecomment-1478305083

ls -la /dev/dri

# check GPU capabilities
sudo apt install -y vainfo
vainfo
```

References:
- https://forum.proxmox.com/threads/alder-lake-gvt-d-integrated-graphics-passthrough.105983/
- https://github.com/strongtz/i915-sriov-dkms

# Debian-specific

Tested on Debian 12.

Alternatively, you can just install proxmox kernel
which is based on debian but have everything enabled by default.

```bash
# check that your kernel is at least 6.1
apt search '^linux-image-.*-amd64' | grep installed
# if you don't, find and install one
apt search '^linux-image-6.*-amd64' | grep 'for 64-bit PCs (signed)' -B 1
sudo apt -y install linux-image-6.1.0-7-amd64
sudo reboot now

# install corresponding sources
sudo apt -y install dwarves linux-source-6.1 pahole vainfo
cd /usr/src
sudo tar xJvf linux-source-6.1.tar.xz

# Copy Debian's original build configuration into the source tree:
sudo cp $(ls /boot/config-6.1.*-amd64 | sort -V | tail -n 1) /usr/src/linux-source-6.1/.config
# enable features required for i915 sriov
echo CONFIG_INTEL_MEI_PXP=m | sudo tee -a /usr/src/linux-source-6.1/.config
echo CONFIG_DRM_I915_PXP=y | sudo tee -a /usr/src/linux-source-6.1/.config

cd /usr/src/linux-source-6.1
# this will take a long time...
# you also need at least 32 GB of total disk space if you are doing it on a completely fresh system
# optimally you want to increase the size to 40+ GB if you have anything installed
sudo make deb-pkg LOCALVERSION=-sriov KDEB_PKGVERSION=$(make kernelversion)-1 -j$(( $(nproc) * 2 )) ARCH=$(arch)
sudo dpkg -i /usr/src/*.deb
sudo reboot

# verify that you are running a modified kernel
uname -r
```

You can also save resulting `.deb` files and use them on other systems.

```bash
# on your main PC
remote=n100.k8s.lan
scp "$remote":'/usr/src/*.deb' .
scp ./*.deb "$remote":.

# on remote
sudo dpkg -i ./*.deb
# verify that you are running a modified kernel
uname -r
```
