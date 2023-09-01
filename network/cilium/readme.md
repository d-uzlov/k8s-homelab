
# Cilium

Cilium is an alternative CNI, with the main feature of being eBPF-only.

# Generate deployment

```bash
helm repo add cilium https://helm.cilium.io/

helm template cilium cilium/cilium \
  --version 1.14.1 \
  --namespace cilium \
  --set tunnel=geneve \
  --set kubeProxyReplacement=strict \
  --set rollOutCiliumPods=true \
  --set operator.rollOutPods=true \
  --set k8sServiceHost=cp.k8s.lan \
  --set k8sServicePort=6443 \
  --set ipam.mode=cluster-pool \
  --set loadBalancer.mode=hybrid \
  --set loadBalancer.dsrDispatch=geneve \
  --set encryption.enabled=true \
  --set encryption.type=wireguard \
  --set ipam.operator.clusterPoolIPv4PodCIDRList=10.201.0.0/16 \
  > ./network/cilium/deploy.yaml
```

`loadBalancer.mode=dsr` disables SNAT for all ingress traffic but reduces MTU.
`loadBalancer.mode=hybrid` disables SNAT for TCP traffic without changing the MTU.

# Deploy

```bash
kl create ns cilium
kl apply -f ./network/cilium/deploy.yaml --server-side=true
```

# Cilium CLI

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium version --client

# if you are using a custom kubecondif location
KUBECONFIG=$KUBECONFIGLOCAL cilium status -n cilium
# or define a short alias
function cilium() {
  KUBECONFIG=$KUBECONFIGLOCAL /usr/local/bin/cilium -n cilium "$@"
}
cilium status

# there is also a different cilium cli tool,
# which seems to have completely different args and output structure
kl -n cilium exec ds/cilium -c cilium-agent -- cilium status
```
