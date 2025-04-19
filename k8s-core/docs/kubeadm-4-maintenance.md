
# Kubeadm maintenance

This file is a cheat sheet for various maintenance tasks for a cluster created using kubeadm.

# Change kubeadm cluster config

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/

Check out example [cluster config](./kubeadm-config/cluster.yaml).

Cluster config is a composite config for:
- apiserver
- controller-manager
- scheduler
- etcd

```bash

# Option 1: download config, edit it, then push it back to cluster
kl -n kube-system get cm kubeadm-config -o 'go-template={{index .data "ClusterConfiguration"}}' > ./k8s-core/docsenv/cluster-config.yaml

kl create cm kubeadm-config --dry-run=client -o yaml --from-file ClusterConfiguration=./k8s-core/docsenv/cluster-config.yaml | kl -n kube-system replace cm kubeadm-config -f -

# Option 2: edit config in place
kl -n kube-system edit cm kubeadm-config

# when configmap contains desired config,
# ssh into each master nodes and run kubeadm
sudo kubeadm upgrade node phase control-plane --patches ./patches/

```

# Change kubelet config

```bash

# Option 1: download config, edit it, then push it back to cluster
kl -n kube-system get cm kubelet-config -o 'go-template={{index .data "kubelet"}}' > ./k8s-core/docsenv/kubelet-config.yaml

kl create cm kubelet-config --dry-run=client -o yaml --from-file kubelet=./k8s-core/docsenv/kubelet-config.yaml | kl -n kube-system replace cm kubelet-config -f -

# Option 2: edit config in place
kl -n kube-system edit cm kubelet-config

# ssh into each node and run:
#   for control plane nodes
sudo kubeadm upgrade node phase kubelet-config --patches ./patches/
#   for worker nodes
sudo kubeadm upgrade node phase kubelet-config

# if something is broken, and you can't connect from node to cluster, you can edit kubelet locally
sudo nano /var/lib/kubelet/config.yaml

# apply new config
sudo systemctl restart kubelet
sudo systemctl status kubelet --no-pager

# you can also manually add extra args to kubelet
sudo nano /etc/default/kubelet
sudo cat /etc/default/kubelet

```

# Remove node from cluster

First remove pods and the node itself using kubectl:

```bash
kl drain n100.k8s.lan --ignore-daemonsets --delete-emptydir-data
kl delete node n100.k8s.lan
```

Then ssh into the removed node and disable kubelet:

```bash
sudo kubeadm reset --force
sudo rm -rf /etc/cni/
sudo rm -rf /var/lib/kubelet/
sudo reboot
```

When using local etcd, master node removal requires additional configuration.
For example: https://paranoiaque.fr/en/2020/04/19/remove-master-node-from-ha-kubernetes/

# Upgrade kubeadm and cluster

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/

```bash

# check out the latest stable release
# see also: https://kubernetes.io/releases/
echo $(curl -Ls https://dl.k8s.io/release/stable.txt)

# you need to upgrade one major version at a time

new_version=v1.32
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/$new_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'"$new_version"'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt autoremove -y
sudo apt full-upgrade -y
sudo apt autoremove -y

apt-cache policy kubeadm | head

new_package_version=1.32.3
sudo apt-mark unhold kubeadm kubelet && \
sudo apt-get install -y kubeadm="$new_package_version"'-*' kubelet="$new_package_version"'-*' && \
sudo apt-mark hold kubeadm kubelet &&
sudo systemctl daemon-reload && sudo systemctl restart kubelet

kubeadm version

# `kubeadm upgrade plan` may fail immediately after kubelet upgrade, wait a bit if this happens

# === choose one node of the cluster ===
# this node must have the /etc/kubernetes/admin.conf file
# study the upgrade plan manually
sudo kubeadm upgrade plan
# choose a version offered by the upgrade plan
sudo kubeadm upgrade apply v1.32.3 --patches ./patches/
sudo kubeadm upgrade apply v1.32.3 --patches ./patches/ --skip-phases addon/kube-proxy
# if you disabled kube-proxy for your CNI, you need to re-disable it again after the upgrade

# On all remaining master nodes
sudo kubeadm upgrade node --patches ./patches/

# === on all other nodes ===
# - repeat upgrade via apt-get
# - run `upgrade node` instead of `upgrade apply`
# on worker nodes this should finish instantly
sudo kubeadm upgrade node

```

# Edit kubelet args

```bash

sudo cat /etc/default/kubelet
echo "KUBELET_EXTRA_ARGS=--housekeeping-interval=5s" | sudo tee /etc/default/kubelet

```

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#reflecting-clusterconfiguration-changes-on-control-plane-nodes
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd

# Update static pod manifests

```bash

sudo kubeadm init phase control-plane all --config ./kconf.yaml
sudo kubeadm init phase etcd local --config ./kconf.yaml
sudo kubeadm init phase upload-certs --upload-certs --config ./kconf.yaml

```

# Kubelet logs

```bash

# it's convenient to delete all logs, for easier reading
# WARNING: this will delete all node logs, not just from kubelet
sudo journalctl --rotate && sudo journalctl -m --vacuum-time=1s
sudo systemctl restart kubelet

# show full logs
journalctl -x --unit kubelet
# show last 50 lines
journalctl -x -n 50 --unit kubelet

```

# Attempt at changing the master node IP address

**Warning!**: These are just notes, not instructions.
I wan't able to fix all the errors and ended up with a broken cluster.
I should note that the cluster was using internal ETCD.
Maybe it might have worked if etcd was external.

```bash
# list all phases
kubeadm init --help
# if you changed list of SANs
sudo rm /etc/kubernetes/pki/*.crt
sudo rm /etc/kubernetes/pki/*.key
sudo kubeadm init phase certs all --config ./kconf.yaml
sudo kubeadm init phase kubeconfig all --config ./kconf.yaml
sudo kubeadm certs renew all

# if you changed master node IP address, you may need to also manually edit kubeconfig files
sudo nano /etc/kubernetes/controller-manager.conf
sudo nano /etc/kubernetes/scheduler.conf
```
