
# Node preparation for kubeadm

This file describes how to prepare Linux nodes for kubeadm.

# Install custom kernel.

`netkit` requires linux 6.8 or newer.

Cgroup burst requires a strait up custom kernel to work well.

```bash

mkdir linux-6.12.22-burstunlock0
wget -O ./linux-6.12.22-burstunlock0/6.12.22-burstunlock0.zip https://github.com/d-uzlov/k8s-cgroup-burst-controller/releases/download/kernel-debian-6.12/6.12.22-burstunlock0.zip
mkdir ./linux-6.12.22-burstunlock0/no-debug/
unzip -d ./linux-6.12.22-burstunlock0/no-debug/ ./linux-6.12.22-burstunlock0/6.12.22-burstunlock0.zip

sudo apt update
sudo apt install -y libdw1 pahole gcc-12 binutils

sudo dpkg -i ./linux-6.12.22-burstunlock0/no-debug/*.deb

```

# Install containerd and its dependencies

```bash

sudo mkdir -p /etc/containerd &&
# containerd doesn't support config merge:
# - https://github.com/containerd/containerd/issues/5837
# TODO is this needed anymore?
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
