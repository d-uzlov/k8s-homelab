
# Kubeadm dependencies for Debian-based distros

```bash
# Disable SWAP
sudo swapoff -a
sudo systemctl mask swap.img.swap
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# dependencies for apt
sudo apt-get install -y ca-certificates curl apt-transport-https gnupg
sudo apt install net-tools
sudo apt install ipvsadm

# Containerd
wget https://github.com/containerd/containerd/releases/download/v1.6.17/containerd-1.6.17-linux-amd64.tar.gz
sudo tar Czxvf /usr/local containerd-1.6.17-linux-amd64.tar.gz

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

sudo systemctl status containerd

containerd --version

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# runc
curl -fsSLo runc.amd64 https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# kubeadm + kubelet
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# if you need a specific version
sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00 --allow-downgrades --allow-change-held-packages
sudo apt-get install -y kubelet=1.27.0-00 kubeadm=1.27.0-00 kubectl=1.27.0-00 --allow-downgrades --allow-change-held-packages
```

Old setup:

```bash
sudo sysctl --system

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io

echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf
sudo systemctl restart systemd-modules-load.service
```

# Modify config

[kubelet-config.yaml](./kubelet-config.yaml) file contains an example config for kubeadm.

You can modify it to match your local environment.

At the very least you need to change `controlPlaneEndpoint`.
This is an IP or DNS address that should point to the cluster master node.
The connection should exist even before you create the cluster,
or kubeadm will not be able to connect to it to verify that the cluster is working.

```bash
# you can also get the whole default config
kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration

# Few references for config values:
#   https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
#   https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
```

# Start kubelet

```bash
# Consult your CNI documentation to determine if you need kube-proxy.
# Don't skip it when in doubt.
sudo kubeadm init --config ./kubelet-config.yaml
sudo kubeadm init --skip-phases=addon/kube-proxy --config ./kubelet-config.yaml

# copy kubectl config on control plane machine
rm -r $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# print and copy from control plane into your local machine
sudo cat /etc/kubernetes/admin.conf

# show command for worker nodes to join
kubeadm token create --print-join-command
```

# Destroy cluster

```bash
# on the basic level destroying cluster is simple
yes | sudo kubeadm reset

# however, this can leave some leftover configs.
# For example, CNI configs are not cleared.
# Consult the CNI docs to learn how to clear VM after removing the cluster.
```

# Clear space on disk

If you run many different images in k8s,
local storage will eventually become filled with garbage images.

```bash
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock rmi --prune
```

# Graceful node shutdown

According to documentation it should be as easy as enabling `shutdownGracePeriod` and `shutdownGracePeriodCriticalPods` in config:
https://kubernetes.io/docs/concepts/architecture/nodes/#graceful-node-shutdown

It isn't.

Official documentation doesn't say it explicitly,
but itvaguely implies that you at least need to use `systemd` to run services.
But it's not nearly enough for the feature to work.

There are several issues:

**1. Kubelet may silently fail to register shutdown delay hook**

First, check the list of systemd hooks to see if kubelet at least registered itself for graceful shutdown.

```bash
cat /etc/systemd/logind.conf.d/99-kubelet.conf
# file should contain something like this: InhibitDelayMaxSec=30

systemd-inhibit --list
# output should contain something like this:
# kubelet      0   root 1079   kubelet      shutdown Kubelet needs time to handle node shutdown delay
```

If `systemd-inhibit` output does not contain the kubelet entry, it's probably because someone overrides `InhibitDelayMaxSec`.

In Ubuntu with default settings the limit is always 30 seconds:
- `/usr/lib/systemd/logind.conf.d/unattended-upgrades-logind-maxdelay.conf`

Uninstall `unattended-upgrades` to fix it.

Also, any of the following configs can cause graceful shutdown to stop working:
- `/etc/systemd/logind.conf`
- `/etc/systemd/logind.conf.d/*.conf`
- `/run/systemd/logind.conf.d/*.conf`
- `/usr/lib/systemd/logind.conf.d/*.conf`

Grep `InhibitDelayMaxSec` in files in these directories.

References:
- https://github.com/kubernetes/kubernetes/issues/107043

**2. You must use systemd for shutting down your machine**

`/usr/sbin/shutdown` is an alias to `/bin/systemctl`.

But `systemctl` does not respect systemd inhibitor locks when called as `shutdown`.

You must use `systemctl poweroff` or a DBus shutdown command (but I didn't test it).

If you don't control how the node is shut down,
replace `/usr/sbin/shutdown` with the following script:
```bash
#!/bin/bash
exec systemctl poweroff
```

Alternatively, apprently scheduled shutdown also works:
```bash
shutdown -h +1
```

Same goes for `reboot`.

Shutdown events from power button are supposed to work fine.
I don't have a physical machine to test it.

Shutting down a VM with `qemu-guest-agent` installed also seems to work fine.

References:
- https://github.com/kubernetes/website/pull/26963#issuecomment-794920869
- https://github.com/systemd/systemd/issues/949

**3. Systemd did not respect shutdown lock in older versions**

Apparently, you need version `248` or newer.
I didn't test to find out real minimum version.

References:
- https://github.com/systemd/systemd/issues/949
- https://github.com/systemd/systemd/pull/18316
- https://github.com/systemd/systemd/pull/9356
- https://github.com/systemd/systemd/commit/8885fed4e3a52cf1bf105e42043203c485ed9d92

# Non-graceful shutdown

Apparently, it's possible to force-remove node and all it's pods from the clueter.

https://kubernetes.io/blog/2022/05/20/kubernetes-1-24-non-graceful-node-shutdown-alpha/
