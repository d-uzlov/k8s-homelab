
# kubeadm install

References:
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# Install kubeadm package

```bash
# add k8s repo
k8s_version=v1.30
sudo mkdir -p /etc/apt/keyrings &&
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
curl -fsSL https://pkgs.k8s.io/core:/stable:/$k8s_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'"$k8s_version"'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# check latest available version
sudo apt-get update
# there are 2 commands, use either one
apt-cache policy kubeadm | head -n 15
apt-cache madison kubeadm | head

# Install kubeadm+kubelet:
sudo apt-get install -y kubelet=1.30.5-1.1 kubeadm=1.30.5-1.1 --allow-downgrades --allow-change-held-packages &&
sudo apt-mark hold kubelet kubeadm

# Pull images so you don't have to wait for it when creating the cluster:
sudo kubeadm config images pull
```
