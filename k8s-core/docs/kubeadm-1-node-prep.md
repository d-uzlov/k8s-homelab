
# Node preparation for kubeadm

This file describes how to prepare Linux nodes for kubeadm.

# Use up-to-date kernel

By default Debian 12 uses kernel `6.1.0-18-amd64`, which is a bit outdated.
For example, `netkit` requires 6.8 or newer.

You can install a newer kernel manually. For example, here is how you can install proxmox kernel:

```bash

echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list
sudo wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
# verify
sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
# sha512sum output must be:
# 7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87 /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y proxmox-default-kernel
sudo reboot now

uname -r
# adjust for your kernel version prefix
sudo apt remove -y linux-image-amd64 'linux-image-6.1*'
sudo update-grub

```

# Install containerd and its dependencies

As of versions v1.7.22 and v2.0 containerd can't work with kernel 6.8.8-4-pve properly.
So this guide downloads a modified version which fixes it.
You may want to switch to the official version
of just rebuild the containerd binaries yourself.

```bash

# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# Check new versions here:
# https://github.com/containerd/containerd/releases
# https://github.com/d-uzlov/containerd/releases

containerd_version=2.1.1
containerd_url=https://github.com/containerd/containerd/releases/download/v$containerd_version/containerd-$containerd_version-linux-amd64.tar.gz
# containerd_url=https://github.com/d-uzlov/containerd/releases/download/release-$containerd_version/containerd-$containerd_version-linux-amd64.tar.gz
wget $containerd_url &&
sudo tar Czxvf /usr/local containerd-$containerd_version-linux-amd64.tar.gz &&
rm containerd-$containerd_version-linux-amd64.tar.gz &&
containerd --version

wget https://github.com/containerd/containerd/raw/refs/heads/main/containerd.service &&
sudo mv containerd.service /usr/lib/systemd/system/ &&
sudo systemctl daemon-reload &&
sudo systemctl enable containerd

# Check new versions here:
# https://github.com/opencontainers/runc/releases
runc_version=1.2.6 &&
wget https://github.com/opencontainers/runc/releases/download/v$runc_version/runc.amd64 &&
sudo install -m 755 runc.amd64 /usr/local/sbin/runc &&
rm runc.amd64 &&
sudo runc --version

# Check new versions here:
# https://github.com/kubernetes-sigs/cri-tools/releases
crictl_version=v1.33.0 &&
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$crictl_version/crictl-$crictl_version-linux-amd64.tar.gz &&
sudo tar zxvf crictl-$crictl_version-linux-amd64.tar.gz -C /usr/local/bin &&
rm -f crictl-$crictl_version-linux-amd64.tar.gz &&
crictl --version &&
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

sudo tee /etc/modules-load.d/containerd.conf << EOF &&
overlay
br_netfilter
EOF
sudo systemctl restart systemd-modules-load.service &&

sudo mkdir -p /etc/containerd &&
# containerd doesn't support config merge:
# - https://github.com/containerd/containerd/issues/5837
containerd config default | 
    sed 's/SystemdCgroup \= false/SystemdCgroup \= true/g' | 
    sudo tee /etc/containerd/config.toml > /dev/null 2>&1 &&
sudo systemctl restart containerd &&
sudo systemctl status containerd --no-pager

```

# System config for k8s

```bash

# check if swap is enabled
[ -z "$(sudo swapon -s)" ] || {
  # disable it
  sudo swapoff -a
  sudo systemctl mask swap.img.swap
  sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

```

# Registry cache (optional)

You can configure containerd to use local proxy registry,
so that each node doesn't have to pull image over the internet.

References:
- [Containerd setup for Harbor proxy](./harbor/containerd-proxy.md)
