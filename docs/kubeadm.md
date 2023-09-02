
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
sudo rm /usr/sbin/shutdown && sudo tee /usr/sbin/shutdown <<EOF && sudo chmod 755 /usr/sbin/shutdown
#!/bin/bash
exec systemctl poweroff
EOF
sudo rm /usr/sbin/reboot && sudo tee /usr/sbin/reboot <<EOF && sudo chmod 755 /usr/sbin/reboot
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

sudo iptables -P INPUT ACCEPT &&
sudo iptables -P FORWARD ACCEPT &&
sudo iptables -P OUTPUT ACCEPT &&
sudo iptables -F

# Install kubeadm

Install kubeadm repo key:

```bash
sudo mkdir -p /etc/apt/keyrings &&
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg &&
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

List latest versions:

```bash
sudo apt-get update &&
apt-cache policy kubeadm | head -n 15
```

Install kubeadm+kubelet version:

```bash
sudo apt-get update &&
sudo apt-get install -y kubelet=1.28.1-00 kubeadm=1.28.1-00 --allow-downgrades --allow-change-held-packages &&
sudo apt-mark hold kubelet kubeadm
```

Pull images so you don't have to wait for it when creating the cluster:

```bash
sudo kubeadm config images pull
```

# Install kubectl locally

Run this on your local PC, you don't need kubectl on the server.

```bash
sudo apt-get install -y kubectl=1.28.1-00 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubectl
```

It would be better if kubectl version match kubelet version.

# Modify config

[kubelet-config.yaml](./kubelet-config.yaml) file contains an example config for kubeadm.

You can modify it to match your local environment.

1. Make sure that `controlPlaneEndpoint` points to your master node.

It can be:
- a static IP assigned to a master node;
- DNS name pointing to the master node;
- IP or DNS pointing to external load balancer that redirects connections to the master node;
- etc.

`controlPlaneEndpoint` should be available before you create the cluster.
First kubelet uses it to connect to itself, and will fail to start if it can't connect.

2. Consider if you want to use `serverTLSBootstrap`. It disables default certificate generation.
You will need to generate certificates yourself.
Look here for more details on how to use it: [kubelet-csr-approver](../metrics/kubelet-csr-approver/).

3. You can also print the whole default config:

```bash
kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration
```

4. Validate config before using it:

```bash
kubeadm config validate --config ./kubelet-config.yaml
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

# print kubectl config
sudo cat /etc/kubernetes/admin.conf
# set this config for your local kubectl

# or fetch the config using ssh
ssh m1.k8s.lan sudo cat /etc/kubernetes/admin.conf > ./_env/kubeadm-master-config.yaml

# show command to join worker nodes
sudo kubeadm token create --print-join-command

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

# Remove node from cluster

```bash
kl drain --ignore-daemonsets --delete-local-data nodename
kl delete node nodename
```

Then ssh into the removed node and disable kubelet:

```bash
sudo kubeadm reset
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

First, check the list of `systemd` hooks to see if kubelet at least registered itself for graceful shutdown.

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

In Ubuntu and Debian the limit is 30 seconds:
- `/usr/lib/systemd/logind.conf.d/unattended-upgrades-logind-maxdelay.conf`

Uninstall `unattended-upgrades` to fix it.

References:
- https://github.com/kubernetes/kubernetes/issues/107043

**2. You must use proper shutdown method**

`/usr/sbin/shutdown` and `/usr/sbin/reboot` are aliases to `/bin/systemctl`.

But `systemctl` does not respect `systemd` inhibitor locks when called as `shutdown` or `reboot`.

You must use `systemctl poweroff` or `systemctl reboot` respectively.

If you don't control how the node is shut down,
replace `/usr/sbin/shutdown` with the following script:
```bash
#!/bin/bash
exec systemctl poweroff
```

Alternatively, apparently scheduled shutdown also works:
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

# Upgrade cluster

References:
- Https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

# Delete failed pods

During graceful shutdown k8s likes to create a myriad of pods in a `Failed` state,
that couldn't run because the node was shutting down. Duh.

These pods remain in the list even after cluster has rebooted and all working pods are scheduled.

```bash
# show pods
kl get pods --field-selector status.phase=Failed --all-namespaces
kl get pods --field-selector status.phase=Succeeded --all-namespaces

# delete pods
kl delete pods --field-selector status.phase=Failed --all-namespaces
kl delete pods --field-selector status.phase=Succeeded --all-namespaces
```
