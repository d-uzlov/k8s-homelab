
# kubeadm install

This file describes how to prepare Linux nodes for kubeadm.

# Install required or useful dependencies

```bash
sudo apt-get install -y qemu-guest-agent ncat net-tools bash-completion iperf3 nfs-common fio ca-certificates curl apt-transport-https gnupg htop open-iscsi cachefilesd dnsutils ipvsadm
```

# Install containerd

```bash
# Check new versions here:
# https://github.com/containerd/containerd/releases
wget https://github.com/containerd/containerd/releases/download/v1.7.5/containerd-1.7.5-linux-amd64.tar.gz &&
sudo tar Czxvf /usr/local containerd-1.7.5-linux-amd64.tar.gz &&

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service &&
sudo mv containerd.service /usr/lib/systemd/system/ &&
sudo systemctl daemon-reload &&
sudo systemctl enable --now containerd &&

sudo systemctl status containerd --no-pager &&
containerd --version &&

# Check new versions here:
# https://github.com/opencontainers/runc/releases
wget https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64 &&
sudo install -m 755 runc.amd64 /usr/local/sbin/runc &&

sudo tee /etc/modules-load.d/containerd.conf <<EOF &&
overlay
br_netfilter
EOF
sudo systemctl restart systemd-modules-load.service &&

sudo mkdir -p /etc/containerd &&
containerd config default | sed 's/SystemdCgroup \= false/SystemdCgroup \= true/g' | sudo tee /etc/containerd/config.toml >/dev/null 2>&1 &&
sudo systemctl restart containerd
```

References:
- https://github.com/containerd/containerd/blob/main/docs/getting-started.md

# Setup shutdown commands for k8s

```bash
sudo rm /usr/sbin/shutdown && sudo tee /usr/sbin/shutdown << EOF && sudo chmod 755 /usr/sbin/shutdown
#!/bin/bash
exec systemctl poweroff
EOF
sudo rm /usr/sbin/reboot && sudo tee /usr/sbin/reboot << EOF && sudo chmod 755 /usr/sbin/reboot
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

# Install kubeadm package

Install kubeadm repo key:

```bash
sudo mkdir -p /etc/apt/keyrings &&
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg &&
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

List latest versions:

```bash
sudo apt-get update
# there are 2 commands, use either one
apt-cache policy kubeadm | head -n 15
apt-cache madison kubeadm | head
```

Install kubeadm+kubelet:

```bash
sudo apt-get update &&
sudo apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 --allow-downgrades --allow-change-held-packages &&
sudo apt-mark hold kubelet kubeadm
```

Pull images so you don't have to wait for it when creating the cluster:

```bash
sudo kubeadm config images pull
```
