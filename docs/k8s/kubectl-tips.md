
# kubectl tips

This file describes various useful kubectl commands.

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

# Bash completion

References:
- [kubectl bash completion](../bash.md#kubectl-completion)

# Show pods from a certain node

```bash
kl get pod -A --field-selector spec.nodeName=n100.k8s.lan
```

# Re-initialize CNI on the node

One time I [gracefully!] rebooted all nodes in my cluster,
and after the reboot there was no cluster connectivity for unknown reason.

Rebooting the nodes did nothing.

Deleting CNI pods did nothing.

The easy way to solve this is to completely re-initialize CNI on the node.

Run on the node with network issues:

```bash
sudo rm -rf /etc/cni/ && sudo reboot
```

# Taint nodes if necessary

```bash
kl taint nodes nodename key=value:type
kl label node nodename key=value
# value is optional
# for example
kl taint nodes --overwrite n100.k8s.lan weak-node=:PreferNoSchedule
kl label node --overwrite n100.k8s.lan weak-node=
```

Key and value can be whatever.

Allowed types are:
- `NoExecute`
- `NoSchedule`
- `PreferNoSchedule`
