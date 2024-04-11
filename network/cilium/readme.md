
# Cilium

Cilium is an alternative CNI, with the main feature of being eBPF-only.

References:
- https://github.com/cilium/cilium

# Generate deployment

You need to regenerate the deployment if you use control plane endpoint other than `cp.k8s.lan`.

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update cilium
helm search repo cilium/cilium --versions --devel | head
helm show values cilium/cilium --version 1.15.3 > ./network/cilium/default-values.yaml

# replace with your value
control_plane_endpoint=cp.k8s.lan
helm template cilium cilium/cilium \
  --version 1.15.3 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=$control_plane_endpoint \
  > ./network/cilium/cilium-native.gen.yaml
helm template cilium cilium/cilium \
  --version 1.15.3 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=$control_plane_endpoint \
  --set l2announcements.enable=true \
  > ./network/cilium/cilium-native-l2lb.gen.yaml
helm template cilium cilium/cilium \
  --version 1.15.3 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --set k8sServiceHost=$control_plane_endpoint \
  --set routingMode=tunnel \
  --set autoDirectNodeRoutes=false \
  --set loadBalancer.dsrDispatch=geneve \
  > ./network/cilium/cilium-tunnel.gen.yaml
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
Also, `l2lb` doesn't work without kube-proxy replacement.

# Deploy

```bash
kl create ns cilium

# choose one of the deployment options:
# - choose native when using a single L2 segment
kl apply -f ./network/cilium/cilium-native.gen.yaml --server-side=true
# - also enable L2 announcements, when not using any other load balancer provider
kl apply -f ./network/cilium/cilium-native-l2lb.gen.yaml --server-side=true
# - choose tunnel when nodes are in different L2 segments
#   tunnel has worse performance than native,
#   see test/iperf folder for details
kl apply -f ./network/cilium/cilium-tunnel.gen.yaml --server-side=true

# check that pods are running
kl -n cilium get pod -o wide
```

# Setup load balancer IPAM for load balancer services

Cilium picks up services without load balancer class specified,
and services with class `io.cilium/l2-announcer`.

```bash
mkdir -p ./network/cilium/loadbalancer/env/
cat <<EOF > ./network/cilium/loadbalancer/env/ip-pool.env
pool=10.0.2.0/24
EOF
```

```bash
kl apply -k ./network/cilium/loadbalancer/
kl get ciliumloadbalancerippool
kl get ciliuml2announcementpolicy
kl -n cilium get lease
```

Test: [ingress example](../../test/ingress/readme.md)

References:
- https://docs.cilium.io/en/latest/network/l2-announcements/
- https://docs.cilium.io/en/stable/network/lb-ipam/#lb-ipam
- https://github.com/cilium/cilium/issues/26586

# Cleanup

```bash
kl delete -k ./network/cilium/loadbalancer/
kl delete -f ./network/cilium/cilium-tunnel.gen.yaml
kl delete -f ./network/cilium/cilium-tunnel-l2lb.gen.yaml
kl delete -f ./network/cilium/cilium-tunnel-l2lb-dsr.gen.yaml
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
