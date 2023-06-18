
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
sudo systemctl restart systemd-modules-load.service

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

# install latest version
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# if you need a specific version
sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00 --allow-downgrades --allow-change-held-packages
sudo apt-get install -y kubelet=1.27.0-00 kubeadm=1.27.0-00 kubectl=1.27.0-00 --allow-downgrades --allow-change-held-packages
```

# Modify config

[kubelet-config.yaml](./kubelet-config.yaml) file contains an example config for kubeadm.

You can modify it to match your local environment.

Make sure that `controlPlaneEndpoint` points to your master node.

It can be: a static IP assigned to a master node;
DNS name pointing to the master node;
IP or DNS pointing to external load balancer that redirects connections to the master node;
etc.

`controlPlaneEndpoint` should be available before you create the cluster.
First kubelet uses it to connect to itself, and will fail to start if it can't connect.

Consider if you want to use `serverTLSBootstrap`. It disables default certificate generation.
Look here for more details how to use it: [kubelet-csr-approver](../metrics/kubelet-csr-approver/).

```bash
# you can also get the whole default config
kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration

# References for config values:
#   https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
#   https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
```

# Start kubelet

Before using `kubeadm` create a `kubelet-config.yaml` file.
An example of the config is available here: [kubelet-config.yaml](./kubelet-config.yaml).

If you are using [kube-vip](../network/kube-vip/),
refer to its documentation for list of things
you need to do before and after using kubeadm.

```bash
# Generic installation
sudo kubeadm init --config ./kubelet-config.yaml
# Calico with eBPF (or probably any other CNI with eBPF)
sudo kubeadm init --skip-phases=addon/kube-proxy --config ./kubelet-config.yaml

# (optionally) copy kubectl config on a control plane machine, for local access
rm -r $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# print and copy from a control plane into your local machine
sudo cat /etc/kubernetes/admin.conf

# show command to join worker nodes
kubeadm token create --print-join-command

# show command to join additional control plane nodes
echo $(kubeadm token create --print-join-command) --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)
# Be careful, control plane nodes require additional setup
# to be turned off, disabled, or be removed from cluster in some other way.
# If you make 2 control plane nodes and one goes down, the second one will fail
# because etcd requires at least (n/2)+1 nodes to be available to work.
# Example how to remove control plane node:
#   https://paranoiaque.fr/en/2020/04/19/remove-master-node-from-ha-kubernetes/
```

# Kubelet logs

```bash
sudo systemctl status kubelet.service

# show full logs
journalctl -xu kubelet

# it is advised to clear logs before kubelet restart, if you want to read them
# WARNING: this will delete all logs, not only from kubelet
sudo journalctl --rotate
sudo journalctl -m --vacuum-time=1s
```

# Destroy cluster

```bash
# on the basic level destroying cluster is simple
sudo kubeadm reset --force

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
but it vaguely implies that you at least need to use `systemd` to run services.

There are several unintuitive issues that can prevent graceful shutdown:

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

Any of the following configs can set the wrong limit:
- `/etc/systemd/logind.conf`
- `/etc/systemd/logind.conf.d/*.conf`
- `/run/systemd/logind.conf.d/*.conf`
- `/usr/lib/systemd/logind.conf.d/*.conf`

Grep `InhibitDelayMaxSec` in files in these directories.

In Ubuntu the limit is 30 seconds:
- `/usr/lib/systemd/logind.conf.d/unattended-upgrades-logind-maxdelay.conf`

Uninstall `unattended-upgrades` to fix it.

References:
- https://github.com/kubernetes/kubernetes/issues/107043

**2. You must use proper shutdown method**

`/usr/sbin/shutdown` and `/usr/sbin/reboot` are aliases to `/bin/systemctl`.

But `systemctl` does not respect systemd inhibitor locks when called as `shutdown` or `reboot`.

You must use `systemctl poweroff` or `systemctl reboot` respectively.

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

DBus shutdown is supposed to work fine but I don't have a way to test this.

Shutdown events from power button are supposed to work fine.
I don't have a physical machine to test it.

Shutting down a VM with `qemu-guest-agent` installed also seems to work fine.

References:
- https://github.com/kubernetes/website/pull/26963#issuecomment-794920869
- https://github.com/systemd/systemd/issues/949

**3. Systemd did not respect shutdown lock in older versions**

Apparently, you need version `248` or newer.
I didn't test to find out real minimum version.

Results in this documentations were obtained using version `249.11` in `Ubuntu 22.04.1`.

References:
- https://github.com/systemd/systemd/issues/949
- https://github.com/systemd/systemd/pull/18316
- https://github.com/systemd/systemd/pull/9356
- https://github.com/systemd/systemd/commit/8885fed4e3a52cf1bf105e42043203c485ed9d92

# Graceful node shutdown doesn't delete pods

References:
- https://github.com/kubernetes/kubernetes/pull/108941
- https://github.com/kubernetes/kubernetes/issues/113278
- https://github.com/kubernetes/kubernetes/issues/113278#issuecomment-1406294874
- https://stackoverflow.com/a/75761843
- https://stackoverflow.com/questions/40296056/kubernetes-delete-all-the-pods-from-the-node-before-reboot-or-shutdown-using-k
- https://kubernetes.io/docs/concepts/architecture/garbage-collection/
- https://longhorn.io/docs/archives/0.8.0/users-guide/node-failure/

# Non-graceful shutdown

Apparently, it's possible to force-remove node and all it's pods from the cluster.

https://kubernetes.io/blog/2022/05/20/kubernetes-1-24-non-graceful-node-shutdown-alpha/

# Certificates

References:
- https://particule.io/en/blog/kubeadm-metrics-server/
- https://www.zeng.dev/post/2023-kubeadm-enable-kubelet-serving-certs/
