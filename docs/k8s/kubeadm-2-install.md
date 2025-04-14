
# kubeadm install

References:
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# Install kubeadm package

```bash

# check out the latest stable release
# see also: https://kubernetes.io/releases/
echo $(curl -Ls https://dl.k8s.io/release/stable.txt)

# add k8s repo
k8s_version=v1.32
sudo mkdir -p /etc/apt/keyrings &&
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
curl -fsSL https://pkgs.k8s.io/core:/stable:/$k8s_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'"$k8s_version"'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
# check latest available version
# there are 2 commands, use either one
apt-cache policy kubeadm | head -n 15
apt-cache madison kubeadm | head

package_version=1.32.3-1.1
sudo apt-get install -y kubeadm=$package_version kubelet=$package_version --allow-downgrades --allow-change-held-packages &&
sudo apt-mark hold kubeadm kubelet &&
sudo systemctl daemon-reload && sudo systemctl restart kubelet

```
