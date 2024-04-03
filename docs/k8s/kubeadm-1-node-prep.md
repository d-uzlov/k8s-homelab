
# kubeadm install

This file describes how to prepare Linux nodes for kubeadm.

# Install required or useful dependencies

```bash
sudo apt-get install -y qemu-guest-agent ncat net-tools bash-completion iperf3 nfs-common fio ca-certificates curl apt-transport-https gnupg htop open-iscsi cachefilesd dnsutils ipvsadm
```

# Install containerd

```bash
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# Check new versions here:
# https://github.com/containerd/containerd/releases
containerd_version=1.7.14
wget https://github.com/containerd/containerd/releases/download/v$containerd_version/containerd-$containerd_version-linux-amd64.tar.gz &&
sudo tar Czxvf /usr/local containerd-$containerd_version-linux-amd64.tar.gz &&
rm containerd-$containerd_version-linux-amd64.tar.gz &&
containerd --version &&

wget https://github.com/containerd/containerd/raw/v$containerd_version/containerd.service &&
sudo mv containerd.service /usr/lib/systemd/system/ &&
sudo systemctl daemon-reload &&
sudo systemctl enable containerd &&

# Check new versions here:
# https://github.com/opencontainers/runc/releases
runc_version=1.1.12
wget https://github.com/opencontainers/runc/releases/download/v$runc_version/runc.amd64 &&
sudo install -m 755 runc.amd64 /usr/local/sbin/runc &&
rm runc.amd64 &&
sudo runc --version &&

sudo tee /etc/modules-load.d/containerd.conf <<EOF &&
overlay
br_netfilter
EOF
sudo systemctl restart systemd-modules-load.service &&

sudo mkdir -p /etc/containerd &&
containerd config default | 
    sed 's/SystemdCgroup \= false/SystemdCgroup \= true/g' | 
    sudo tee /etc/containerd/config.toml > /dev/null 2>&1 &&
sudo systemctl restart containerd &&
sudo systemctl status containerd --no-pager
```

# Setup shutdown commands for k8s

Default `shutdown` and `reboot` commands don't allow for k8s graceful shutdown.

```bash
sudo tee /usr/sbin/shutdown << EOF && sudo chmod 755 /usr/sbin/shutdown
#!/bin/bash
exec systemctl poweroff
EOF
sudo tee /usr/sbin/reboot << EOF && sudo chmod 755 /usr/sbin/reboot
#!/bin/bash
exec systemctl reboot
EOF
```

# Kubeadm dependencies for Debian-based distros

```bash
# check if swap is enabled
[ -z "$(sudo swapon -s)" ] || {
  # disable it
  sudo swapoff -a
  sudo systemctl mask swap.img.swap
  sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF &&
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# reload rules from /etc/sysctl.d
sudo sysctl --system
```

# Registry cache (optional)

You can configure containerd to use local proxy registry,
so that each node doesn't have to pull image over the internet.

References:
- [Containerd setup for Harbor proxy](./harbor/containerd-proxy.md)

# Misc

References:
- K8s hangs when deleting pod with failed NFS mount: https://github.com/kubernetes/kubernetes/issues/101622
