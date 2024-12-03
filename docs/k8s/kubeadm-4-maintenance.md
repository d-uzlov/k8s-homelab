
# Kubeadm maintenance

This file is a cheat sheet for various maintenance tasks for a cluster created using kubeadm.

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
curl -Ls https://dl.k8s.io/release/stable.txt

new_version=v1.30
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'"$new_version"'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
apt-cache policy kubeadm | head

# first upgrade just kubeadm
new_package_version=1.30.0
sudo apt-mark unhold kubeadm kubelet && \
sudo apt-get install -y kubeadm="$new_package_version"'-*' kubelet="$new_package_version"'-*' && \
sudo apt-mark hold kubeadm kubelet &&
sudo systemctl daemon-reload && sudo systemctl restart kubelet

kubeadm version

# === choose one node of the cluster ===
# this node must have the /etc/kubernetes/admin.conf file
# study the upgrade plan manually
sudo kubeadm upgrade plan --config ./kconf.yaml
# choose a version offered by the upgrade plan
sudo kubeadm upgrade apply v1.30.0 --config ./kconf.yaml
# if you disabled kube-proxy for your CNI, you need to re-disable it again after the upgrade

# === on all other nodes ===
# - repeat upgrade via apt-get
# - run `upgrade node` instead of `upgrade apply`
# on control plane nodes this can take some time
# on worker nodes this should finish instantly
sudo kubeadm upgrade node --certificate-renewal=false
```

# Edit kubelet args

```bash
sudo cat /etc/default/kubelet
echo "KUBELET_EXTRA_ARGS=--housekeeping-interval=5s" | sudo tee /etc/default/kubelet
```

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#reflecting-clusterconfiguration-changes-on-control-plane-nodes
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd

# Change kubelet config

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/

```bash
# check current kubelet config
# (run this on a cluster node)
sudo cat /var/lib/kubelet/config.yaml

# generate new config
# fill in your values
control_plane_endpoint=cp.k8s.lan
serverTLSBootstrap=true
sed \
  -e "s/REPLACE_ME_SERVER_TLS_BOOTSTRAP/$serverTLSBootstrap/" \
  ./docs/k8s/kubeadm-config/kubelet.yaml \
  > ./docs/k8s/env/kubelet-$control_plane_endpoint.yaml

kl -n kube-system create cm kubelet-config --from-file=kubelet=./docs/k8s/env/kubelet-$control_plane_endpoint.yaml -o yaml --dry-run=client | kl apply -f -

# then run this on all of the nodes
sudo kubeadm upgrade node phase kubelet-config
# you can also edit /var/lib/kubelet/kubeadm-flags.env to adjust node-specific config
sudo systemctl restart kubelet
```

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
