
# Cilium

Cilium is an alternative CNI, with the main feature of being eBPF-only.

# Generate deployment

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update cilium
helm search repo cilium/cilium --versions --devel | head
helm show values cilium cilium/cilium --version 1.14.1 > ./network/cilium/default-values.yaml

helm template cilium cilium/cilium \
  --version 1.14.1 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=cp.k8s.lan \
  > ./network/cilium/deploy.gen.yaml
```

# Deploy

```bash
kl create ns cilium
kl apply -f ./network/cilium/deploy.gen.yaml --server-side=true
# check that pods are running
kl -n cilium get pod
```

# Cilium CLI

Cilium CLI is not strictly required but it can be very convenient to use.

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium version --client

# if you are using a custom kubecondig, set it before running the command
KUBECONFIG=$KUBECONFIGLOCAL cilium status -n cilium
# or define a short alias
function cilium() {
  KUBECONFIG=$KUBECONFIGLOCAL /usr/local/bin/cilium -n cilium "$@"
}
# check that the tool works
cilium status
```

You can also run `cilium` tool in the cilium pod
but it seems to have completely different args and output structure.

```bash
kl -n cilium exec ds/cilium -c cilium-agent -- cilium status
```

# Installing using CLI

```bash
cilium install --list-versions | head
cilium install \
  --version=v1.11.1 \
  --values ./network/cilium/values.yaml
```
