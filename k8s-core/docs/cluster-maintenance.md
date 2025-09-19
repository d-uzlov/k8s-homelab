
# k8s cluster maintenance

This file is a cheat sheet for various maintenance tasks

# check kubeconfig certificate expiration

```bash

kubeconfigPath=./_env/cp.k8s.lan.yaml

for certContent in $(cat $kubeconfigPath | grep client-certificate-data | cut -f2 -d : | tr -d ' '); do
  echo $certContent | base64 -d | openssl x509 -text -out - | grep "Not After"
done

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
kl taint nodes node-name key=value:type
kl label node node-name key=value
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
