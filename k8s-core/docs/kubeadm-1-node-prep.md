
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

As of versions v1.7.22 and v2.0 containerd can't work with kernel 6.8.8-4-pve properly.
So this guide downloads a modified version which fixes it.
You may want to switch to the official version
of just rebuild the containerd binaries yourself.

```bash

# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# Check new versions here:
# https://github.com/containerd/containerd/releases

containerd_version=2.1.3
containerd_url=https://github.com/containerd/containerd/releases/download/v$containerd_version/containerd-$containerd_version-linux-amd64.tar.gz
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
runc_version=1.3.0 &&
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
