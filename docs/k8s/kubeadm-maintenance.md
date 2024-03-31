
# kubeadm maintenance

This file describes various maintenance commands for kubeadm-based cluster.

# Edit kubelet args

```bash
echo "KUBELET_EXTRA_ARGS=--housekeeping-interval=5s" | sudo tee /etc/default/kubelet
```

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#reflecting-clusterconfiguration-changes-on-control-plane-nodes
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#the-kubelet-drop-in-file-for-systemd

# Update kubeadm and cluster

List latest versions:

```bash
sudo apt-get update
apt-cache policy kubeadm | head
```

Install new packages on all nodes:

```bash
sudo apt-get update &&
sudo apt-mark unhold kubelet kubeadm &&
sudo apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 &&
sudo apt-mark hold kubelet kubeadm
```

Then upgrade one control plane node:

```bash
sudo kubeadm upgrade plan
# you will see the version that you can upgrade onto
sudo kubeadm upgrade apply v1.28.2 -y &&
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

Then on all other nodes:

```bash
sudo kubeadm upgrade node &&
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

References:
- Https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

# Update cluster config

```bash
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

# Misc

References:
- K8s hangs when deleting pod with failed NFS mount: https://github.com/kubernetes/kubernetes/issues/101622
