
# Cilium

Cilium is an alternative CNI, with the main feature of being eBPF-only.

DSR is broken in 1.14.1 and 1.14.2.

# Generate deployment

You need to regenerate the deployment if you use control plane endpoint other than `cp.k8s.lan`.

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update cilium
helm search repo cilium/cilium --versions --devel | head
helm show values cilium/cilium --version 1.14.2 > ./network/cilium/default-values.yaml

# replace k8sServiceHost with your value
helm template cilium cilium/cilium \
  --version 1.14.2 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=cp.k8s.lan \
  > ./network/cilium/deploy.gen.yaml
helm template cilium cilium/cilium \
  --version 1.14.2 \
  --values ./network/cilium/loadbalancer/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=cp.k8s.lan \
  > ./network/cilium/loadbalancer/deploy.gen.yaml
```

# Disable kube-proxy

Cilium completely replaces kube-proxy so you need to disable it.

```bash
# disable kube-proxy
kl -n kube-system patch ds kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"enable-kube-proxy": "true"}}}}}'
# revert if you uninstall cilium
kl -n kube-system patch ds kube-proxy --type=json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/enable-kube-proxy"}]'
```

It's possible to make Cilium coexist with kube-proxy
if you change Cilium settings but it's more effective to replace it.

# Deploy without load balancer

```bash
kl create ns cilium
kl apply -f ./network/cilium/deploy.gen.yaml --server-side=true
# check that pods are running
kl -n cilium get pod -o wide
```

# Deploy with load balancer

```bash
mkdir -p ./network/cilium/loadbalancer/env/
cat <<EOF > ./network/cilium/loadbalancer/env/ip-pool.env
pool=10.0.2.0/24
EOF
```

```bash
kl create ns cilium

kl apply -f ./network/cilium/loadbalancer/deploy.gen.yaml --server-side=true
kl -n cilium get pod -o wide

kl apply -k ./network/cilium/loadbalancer/
kl get ciliumloadbalancerippool
kl get ciliuml2announcementpolicy
```

Test: [ingress example](../../test/ingress/readme.md)

References:
- https://docs.cilium.io/en/latest/network/l2-announcements/
- https://docs.cilium.io/en/stable/network/lb-ipam/#lb-ipam
- https://github.com/cilium/cilium/issues/26586

# Cleanup

```bash
kl delete -k ./network/cilium/loadbalancer/
kl delete -f ./network/cilium/loadbalancer/deploy.gen.yaml
kl delete -f ./network/cilium/deploy.gen.yaml
kl delete ns cilium
```

# Cilium CLI

Cilium CLI is not strictly required but it can be very convenient to use.

Install:

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium version --client
```

Test connection to cluster:

```bash
# if you are using a custom kubecondig, set it before running the command
KUBECONFIG=$KUBECONFIGLOCAL cilium status -n cilium
# or define a short alias
function cilium() {
  KUBECONFIG=$KUBECONFIGLOCAL /usr/local/bin/cilium -n cilium "$@"
}
# check that the tool works
cilium status

cilium connectivity test
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
