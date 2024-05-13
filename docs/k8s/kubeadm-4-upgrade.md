
# Upgrade kubeadm and cluster

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/

```bash
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
# study the upgrade plan manually
sudo kubeadm upgrade plan --config ./kconf.yaml

# choose a version offered by the upgrade plan
# run only on the first node to upgrade
# this node must have the /etc/kubernetes/admin.conf file
sudo kubeadm upgrade apply v1.30.0 --config ./kconf.yaml
# if you disabled kube-proxy for your CNI, you need to re-disable it again after the upgrade

# on all otehr nodes run `upgrade node` instead of `upgrade apply`
# don't forget to upgrade kubeadm before running it
# on control plane nodes this can take some time
# on worker nodes this should finish instantly
sudo kubeadm upgrade node --certificate-renewal=false
```

# Edit kubelet args

```bash
echo "KUBELET_EXTRA_ARGS=--housekeeping-interval=5s" | sudo tee /etc/default/kubelet
```

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#reflecting-clusterconfiguration-changes-on-control-plane-nodes
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd

# Update cluster config

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/

```bash
# check current kubelet config
# (run this on cluster node)
sudo cat /var/lib/kubelet/config.yaml

# fix kubelet config
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

# list all phases
kubeadm init --help
# if you changed list of SANs
# warning: this is untested, you can break your cluster
sudo rm /etc/kubernetes/pki/*.crt
sudo rm /etc/kubernetes/pki/*.key
sudo kubeadm init phase certs all --config ./kconf.yaml
sudo kubeadm init phase kubeconfig all --config ./kconf.yaml
sudo kubeadm certs renew all

# update static pod manifests
sudo kubeadm init phase control-plane all --config ./kconf.yaml
sudo kubeadm init phase etcd local --config ./kconf.yaml
sudo kubeadm init phase upload-certs --upload-certs --config ./kconf.yaml

# if you changed master node IP address, you may need to also manually edit kubeconfig files
sudo nano /etc/kubernetes/controller-manager.conf
sudo nano /etc/kubernetes/scheduler.conf

sudo systemctl restart kubelet

journalctl -xeu kubelet.service
```
