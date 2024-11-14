
# kubectl tips

This file describes various useful kubectl commands.

# Install kubectl

Usually you don't use kubectl on your server
so you only need to run this on your local machine.

```bash
kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
rm -rf kubectl kubectl.sha256
```

References:
- https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

# Colorized output

`kubectl` doesn't use colors.
`kubecolor` is a wrapped that adds them.

Kubecolor can be used as a direct replacement for kubectl.

Prerequisites:
- [.bashrc directory](../bash.md#add-bashrc-directory)

```bash
# check latest version: https://github.com/kubecolor/kubecolor/releases
kubecolor_version=0.4.0
mkdir -p kubecolor
cd kubecolor
curl -LO "https://github.com/kubecolor/kubecolor/releases/download/v$kubecolor_version/kubecolor_${kubecolor_version}_linux_amd64.tar.gz"
tar -xzf "kubecolor_${kubecolor_version}_linux_amd64.tar.gz"
sudo install -o root -g root -m 0755 kubecolor /usr/local/bin/kubecolor
cd ..
rm -rf kubecolor
```

# Bash completion

Prerequisites:
- [.bashrc directory](../bash.md#add-bashrc-directory)

```bash
 cat << "EOF" > ~/.bashrc.d/998-kubeconfig.sh
export KUBECONFIG_MAIN=
export KUBECONFIG_LOCAL=
EOF
 cat << "EOF" > ~/.bashrc.d/999-kubectl-completion.sh
# enable kubectl completion
source <(kubectl completion bash)

# create both the bash alias and the function alias
# with given name and kubeconfig file
# and enable bash completion for them
function createKubectlAlias() {
  name=$1
  config=$2
  . <(echo 'function '$name'() { kubecolor --kubeconfig "'"$config"'" "$@"; }; export -f '$name'; alias '$name'="kubecolor --kubeconfig='$config'"; complete -o default -F __start_kubectl '$name)
}

createKubectlAlias k "$KUBECONFIG_MAIN"
createKubectlAlias kl "$KUBECONFIG_LOCAL"
EOF
```

Local configuration:
- edit variables in `~/.bashrc.d/998-kubeconfig.sh`
- adjust the amount and name of aliases in `~/.bashrc.d/999-kubectl-completion.sh`

# Show pods from a certain node

```bash
kl get pod -A --field-selector spec.nodeName=n100.k8s.lan
```

# List all resources in a namespace

```bash
# set to your value
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

# Get cluster info

```bash
# cluster domain, cluster CIDR
kl -n kube-system describe cm kubeadm-config
kl describe node | grep -e PodCIDR -e Name:
```
