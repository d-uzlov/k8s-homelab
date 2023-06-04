# Installing k8s on Debian

- Install `sudo`:

  Login as an ordinary user first, then login as root:
  ```shell
  su
  ```
  As root, install sudo:
  ```shell
  apt update
  apt upgrade
  apt install sudo
  ```
  Add user to `/etc/sudoers`:
  ```shell
  sudo adduser user sudo
  ```
  Exit root:
  ```shell
  exit
  ```
  New `sudo` settings start working only after next login, so end your SSH session and log in again.
  Then login again and test:
  ```shell
  sudo apt moo
  ```

- Install Kubernetes:
  ```shell
  sudo apt-get install -y ca-certificates curl apt-transport-https gnupg
  
  wget https://github.com/containerd/containerd/releases/download/v1.6.17/containerd-1.6.17-linux-amd64.tar.gz
  sudo tar Czxvf /usr/local containerd-1.6.17-linux-amd64.tar.gz
  
  wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
  sudo mv containerd.service /usr/lib/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
  
  sudo systemctl status containerd
  
  containerd --version
  
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl
  
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
  sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  sudo systemctl restart containerd
  sudo systemctl enable containerd
  
  sudo swapoff -a
  sudo systemctl mask swap.img.swap
  sudo sed -i '/ swap / s/^/#/' /etc/fstab
  
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
  
  curl -fsSLo runc.amd64 https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
  sudo install -m 755 runc.amd64 /usr/local/sbin/runc
  ```
  
  Add `/usr/local/sbin` to `$PATH` for sudoers:
  ```shell
  sudo visudo
  ```
  
  In the opened `nano` editor, add `/usr/local/sbin` to `$PATH`:
  ```
  Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin"
  ```
  
  Check if that works:
  ```shell
  sudo runc
  ```
  
  Also make `runc` executable by the ordinary user:
  ```shell
  echo 'PATH="$PATH:/usr/local/sbin"' >> ~/.bashrc
  ```
  
  Reopen SSH session and try:
  ```shell
  runc
  ```

  On the master VM, start the master node:
  ```shell
  sudo kubeadm init --pod-network-cidr 10.201.0.0/16 --service-cidr 10.202.0.0/16 --apiserver-advertise-address 0.0.0.0
  ```
  
  Print the command you need to run on worker nodes to connect them to the cluster:
  ```shell
  sudo kubeadm token create --print-join-command
  ```
  
  Copy-paste it into worker nodes and don't forget to add `sudo`. For example:
  ```shell
  sudo kubeadm join 192.168.88.235:6443 --token lh7jdq.8o0fsr9e8fwmp85q --discovery-token-ca-cert-hash sha256:6740e4b24adb1719d6fc8e09df1c341588d1a6da21a1bda5525896d93056eb67
  ```
