
# Transcoding

References:
- https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new
- https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html
- https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/
- https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/

# host

References:
- https://github.com/strongtz/i915-sriov-dkms
- https://forum.proxmox.com/threads/alder-lake-gvt-d-integrated-graphics-passthrough.105983/

```bash
sudo apt install -y build-* dkms git
sudo apt install -y proxmox-headers-$(uname -r)

wget https://github.com/strongtz/i915-sriov-dkms/releases/download/2025.02.03/i915-sriov-dkms_2025.02.03_amd64.deb
sudo dpkg -i ./i915-sriov-dkms_2025.02.03_amd64.deb
# dkms install can take a long time
sudo dkms status
# status must be "installed"

# if sriov driver doesn't load despite dkms package being installed,
# check that headers package is installed and reinstall dkms

sudo nano /etc/kernel/cmdline
# add: intel_iommu=on i915.enable_guc=3 i915.max_vfs=7 module_blacklist=xe

# pin the kernel
sudo proxmox-boot-tool kernel pin $(uname -r)
sudo proxmox-boot-tool kernel pin 6.8.12-5-pve
sudo proxmox-boot-tool kernel list
# when you want to update, unpin:
# sudo proxmox-boot-tool kernel unpin

sudo proxmox-boot-tool refresh
# if you are having issues, you could also try this: update-initramfs -u -k all

lspci -tv
sudo apt install sysfsutils
# replace `00:02` with the address of your GPU as printed by lspci
# this will automatically create virtual GPUs on boot
echo "devices/pci0000:00/0000:00:02.0/sriov_numvfs = 7" | sudo tee -a /etc/sysfs.conf
# alternatively, create vGPUs manually, they will last until reboot
# echo 7 | sudo tee "/sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs"

sudo reboot now

# check that you now have 8 virtual GPUs with addresses 02.0 through 02.7
lspci -tv
```

Note: never use vGPU with index 0: `02.0`.

# guest: prerequisites

Guest kernel must have `CONFIG_INTEL_MEI_PXP=m` and `CONFIG_DRM_I915_PXP=y` set, which Debian 12 doesn't do.
Other distributions shouldn't require any changes.

On debian 12 you can install the proxmox kernel:

```bash
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list
sudo wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
# verify
sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
# sha512sum output must be:
# 7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87 /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y proxmox-default-kernel
sudo apt-mark hold proxmox-default-kernel
sudo reboot now
# adjust for your kernel version prefix
sudo apt remove -y linux-image-amd64 'linux-image-6.1*'
sudo update-grub
```

# guest: installation

```bash
sudo apt install -y build-* dkms git
sudo apt install -y proxmox-headers-$(uname -r)

wget https://github.com/strongtz/i915-sriov-dkms/releases/download/2025.05.18/i915-sriov-dkms_2025.05.18_amd64.deb
sudo dpkg -i ./i915-sriov-dkms_2025.05.18_amd64.deb
# package installation can take a long time
sudo dkms status
# status must be "installed"

# if sriov driver doesn't load despite dkms package being installed,
# check that headers package is installed and reinstall dkms

sudo nano /etc/default/grub
# add to GRUB_CMDLINE_LINUX_DEFAULT: i915.enable_guc=3 module_blacklist=xe
sudo update-grub
sudo update-initramfs -u
sudo reboot now
```

After reboot check that driver successfully loaded.
Don't forget to add the add the PCI device passthrough.

```bash
sudo dmesg | grep i915
# dmesg may show that some symbols are missing
# this is a known issue:
#   https://github.com/strongtz/i915-sriov-dkms/issues/55#issuecomment-1478305083

ls -la /dev/dri/

# check GPU capabilities
sudo apt install -y vainfo
vainfo
```

After a kernel update don't forget to delete old kernels, so DKMS don't build modules for them.
Additionally, remove old kernel references in `/lib/modules/`.
For example:

```bash
sudo rm -r /lib/modules/6.8.12-5-pve/
```
