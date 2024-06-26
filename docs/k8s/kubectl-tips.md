
# kubectl tips

This file describes various useful kubectl commands.

# Install kubectl locally

Usually you don't use kubectl on your server
so you only need to run this on your local machine.

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

References:
- https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

# Bash completion

References:
- [kubectl bash completion](../bash.md#kubectl-completion)

# Show pods from a certain node

```bash
kl get pod -A --field-selector spec.nodeName=n100.k8s.lan
```

# List all resources in a namespace

```bash
# set to your calue
namespace=cilium
kl api-resources --verbs=list --namespaced -o name | xargs -n 1 $(alias kl | sed "s/.*'\(.*\)'.*/\1/g") get --show-kind --ignore-not-found -n $namespace
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

# Delete failed pods

During graceful shutdown k8s likes to create a myriad of pods in a `Failed` state,
that couldn't run because the node was shutting down. Duh.

These pods remain in the list even after cluster has rebooted and all working pods are scheduled.

```bash
# show pods
kl get pods --field-selector status.phase=Failed --all-namespaces
kl get pods --field-selector status.phase=Succeeded --all-namespaces

# delete pods
kl delete pods --field-selector status.phase=Failed --all-namespaces
kl delete pods --field-selector status.phase=Succeeded --all-namespaces
```
