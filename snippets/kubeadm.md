
# установка kubeadm

alt tutorial:
https://blog.radwell.codes/2022/07/single-node-kubernetes-cluster-via-kubeadm-on-ubuntu-22-04/


```bash
sudo apt-get install -y ca-certificates curl apt-transport-https

wget https://github.com/containerd/containerd/releases/download/v1.6.17/containerd-1.6.17-linux-amd64.tar.gz
sudo tar Czxvf /usr/local containerd-1.6.17-linux-amd64.tar.gz

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

sudo systemctl status containerd
containerd --version

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt install -y kubeadm
kubeadm version

sudo swapoff -a
sudo systemctl mask swap.img.swap


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

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf
sudo systemctl restart systemd-modules-load.service

# it's better to change defauld CIRD valus
# kubeadm config print init-defaults
# default cluster CIDR is 10.96.0.0/12
# default service CIDR is 10.96.0.0/12
sudo kubeadm init --control-plane-endpoint kubeadm-master.example --pod-network-cidr 10.201.0.0/16 --service-cidr 10.202.0.0/16 --apiserver-advertise-address 0.0.0.0

rm -r $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo cat /etc/kubernetes/admin.conf

# show command for worker nodes to join
kubeadm token create --print-join-command
```

# Clear space on disk

sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock rmi --prune
