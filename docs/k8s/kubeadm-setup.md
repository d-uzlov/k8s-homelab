
# kubeadm setup

This file describes how to create k8s cluster when you already have ready-to-use nodes.

# Control plane endpoint

You need some stable address that will always point to control plane node(s).

It can be:
- a static IP assigned to a master node;
- DNS name pointing to the master node;
- IP or DNS pointing to external load balancer that redirects connections to the master node;
- etc.

This address must be available before you create the cluster.
Kubelet will fail to start if this address doesn't exist
because it tries to connect to it.

DNS address is recommended, preferably a separate one, not the one linked to the master node.

# Print default config:

```bash
ssh m1.k8s.lan sudo kubeadm config print init-defaults --component-configs KubeletConfiguration,KubeProxyConfiguration > ./docs/k8s/kconf-default.yaml
```

# Setup cluster

Copy config to the first master node:

```bash
# Set to your value
control_plane_endpoint=cp.k8s.lan
# ip of the first control plane node
cp_node1=m1.k8s.lan
sed -e "s/REPLACE_ME_CONTROL_PLANE_ENDPOINT/$control_plane_endpoint/" ./docs/k8s/kconf.yaml | ssh "$cp_node1" "cat > kconf.yaml"
```

Note that this config uses `serverTLSBootstrap: true`,
which means that you will need to setup [CSR approver](../../metrics/kubelet-csr-approver/readme.md).

If you are using [kube-vip control plane](../../network/kube-vip-control-plane/readme.md),
refer to its documentation for list of things
you need to do before and after using kubeadm.

SSH into the master node and create cluster:

```bash
ssh "$cp_node_address"
```

```bash
# validate config
kubeadm config validate --config kconf.yaml

# create cluster
sudo kubeadm init \
    --config kconf.yaml \
    --node-name "$(hostname --fqdn)" \
    --skip-phases show-join-command

# copy admin config to local user folder
mkdir -p $HOME/.kube &&
sudo rm -f $HOME/.kube/config &&
sudo cat /etc/kubernetes/admin.conf > $HOME/.kube/config
```

Fetch admin config file from master node to your local machine:

```bash
scp "$cp_node1":.kube/config ./_env/"$control_plane_endpoint".yaml
```

# Join other nodes

Make sure that you have kubeadm and its dependencies on all nodes.

```bash
ssh "$cp_node1"
```

On a master node:

```bash
# show command to join worker nodes
echo "sudo $(sudo kubeadm token create --print-join-command) --node-name "'$(hostname --fqdn)'

# show command to join additional control plane nodes
echo "sudo $(kubeadm token create --print-join-command) --node-name "'$(hostname --fqdn)'" --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)"
```

Then SSH into the new node and execute the printed command.

- **Warning!**: Be careful, control plane nodes require additional setup
to be turned off, disabled, or be removed from cluster in some other way.
If you make 2 control plane nodes and one goes down, the second one will fail
because etcd requires at least (n/2)+1 nodes to be available to work.
- Example how to remove control plane node:
- - https://paranoiaque.fr/en/2020/04/19/remove-master-node-from-ha-kubernetes/

# Destroy cluster

```bash
# on the basic level destroying cluster is simple
sudo kubeadm reset --force

# however, this can leave some leftover configs.
# For example, CNI configs are not cleared.
# Consult the CNI docs to learn how to clear VM after removing the cluster.
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

# Install kubectl locally

Usually you don't use kubectl on your server
so you only need to run this on your local machine.

```bash
sudo mkdir -p /etc/apt/keyrings &&
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg &&
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-cache policy kubectl | head
```

kubectl version should match version of kubelet.
It's ok if minor version doesn't match.
Major version can differ by ±1.

Bigger version skew can work
(I successfully used kubectl v1.27 with cluster v1.22)
but this is not tested and not supported by the Kubernetes team.

```bash
sudo apt-get update
sudo apt-get install -y kubectl=1.28.1-00 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubectl
```
