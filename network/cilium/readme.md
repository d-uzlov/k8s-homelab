
# Cilium

Cilium is an alternative CNI, with the main feature of being eBPF-only.

References:
- https://github.com/cilium/cilium

# Generate deployment

```bash

helm repo add cilium https://helm.cilium.io/
helm repo update cilium
helm search repo cilium/cilium --versions --devel | head
helm show values cilium/cilium --version 1.18.1 > ./network/cilium/default-values.yaml

helm template cilium cilium/cilium \
  --version 1.18.1 \
  --values ./network/cilium/values.yaml \
  --namespace cilium \
  --api-versions gateway.networking.k8s.io/v1/GatewayClass \
  > ./network/cilium/cilium-native.gen.yaml

# also need to enable masquerading for tunneling but I don't care enough about it to configure and test this config
# helm template cilium cilium/cilium \
#   --version 1.17.4 \
#   --values ./network/cilium/values.yaml \
#   --namespace cilium \
#   --set routingMode=tunnel \
#   --set autoDirectNodeRoutes=false \
#   --set loadBalancer.dsrDispatch=geneve \
#   --set ipv4NativeRoutingCIDR= \
#   --api-versions gateway.networking.k8s.io/v1/GatewayClass \
#   > ./network/cilium/cilium-tunnel.gen.yaml

```

# Deploy

```bash

mkdir -p ./network/cilium/env/
 cat << EOF > ./network/cilium/env/control-plane-endpoint.env
# ip or domain that points to your control plane nodes
# same as what you set during cluster creation
control_plane_endpoint=cp.k8s.lan
EOF

kl create ns cilium
kl label ns cilium pod-security.kubernetes.io/enforce=privileged
kl label ns cilium pod-name.meoe.io/policy=ignore
kl label ns cilium kubernetes.io/namespace-type=system-critical --overwrite
kl create ns cilium-secrets

kl -n cilium apply -f ./network/network-policies/deny-ingress.yaml
kl -n cilium apply -f ./network/network-policies/allow-same-namespace.yaml

( . ./network/cilium/env/control-plane-endpoint.env && sed "s/cp-address-automatic-replace/$control_plane_endpoint/" ./network/cilium/cilium-native.gen.yaml | kl apply -f - )

kl -n cilium get pod -o wide

kl -n cilium delete job hubble-generate-certs

kl apply -k ./network/cilium/hubble-ingress-route/
kl apply -k ./network/cilium/httproute-hubble-authentik/
kl -n cilium get htr

```

# Cleanup

```bash
kl delete -k ./network/cilium/loadbalancer/
kl delete -f ./network/cilium/cilium-tunnel.gen.yaml
kl delete -f ./network/cilium/cilium-tunnel-l2lb.gen.yaml
kl delete -f ./network/cilium/cilium-tunnel-l2lb-dsr.gen.yaml
kl delete ns cilium
```

# Disable kube-proxy

```bash

# cilium completely replaces kube-proxy so you need to disable it.
#   disable kube-proxy
kl -n kube-system patch ds kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"enable-kube-proxy": "true"}}}}}'
#   revert if you uninstall cilium
kl -n kube-system patch ds kube-proxy --type=json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/enable-kube-proxy"}]'
# It's possible to make Cilium coexist with kube-proxy
# if you change Cilium settings but it's more effective to replace it.
# Also, `l2lb` doesn't work without kube-proxy replacement.

```

# Configure node IPAM (required)

Without any additional settings cilium searches for ip pool with name default.
You can define additional pools, and use them by selecting them
on node (via CiliumNode config), namespace (via annotation) or pod (via annotation).

Set `ipam.cilium.io/ip-pool=pool-name` annotation on pod or namespace to select non-default pool.

```bash

cat << EOF > ./network/cilium/env/ip-pool-default.yaml
---
apiVersion: cilium.io/v2alpha1
kind: CiliumPodIPPool
metadata:
  name: default
spec:
  ipv4:
    cidrs:
    - 10.3.128.0/18
    maskSize: 24
EOF

kl apply -f ./network/cilium/env/ip-pool-default.yaml

kl get cpip

```

# Setup load balancer IPAM for load balancer services (optional)

Cilium picks up services without load balancer class specified,
and services with class `io.cilium/l2-announcer`.

```bash

mkdir -p ./network/cilium/loadbalancer/env/
 cat << EOF > ./network/cilium/loadbalancer/env/ip-pool.env
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

# Cilium CLI

Cilium CLI is not strictly required but sometimes it can be convenient to use.

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

# if you are using a custom kubeconfig, set it before running the command
KUBECONFIG=$KUBECONFIG_LOCAL cilium status -n cilium
# or define a short alias
function cilium() {
  KUBECONFIG=$KUBECONFIG_LOCAL /usr/local/bin/cilium -n cilium "$@"
}
# check that the tool works
cilium status
cilium version

cilium connectivity test

```

You can also run `cilium` tool in the cilium pod
but it seems to have completely different args and output structure.

```bash

kl -n cilium exec ds/cilium -c cilium-agent -- cilium status

```

# Manual metric checking

```bash

kl exec deployments/alpine -- curl -sS http://10.3.10.0:9963/metrics > ./cilium-operator-metrics.log
kl exec deployments/alpine -- curl -sS http://hubble-metrics.cilium:9965/metrics > ./cilium-hubble-metrics.log
# get metrics from a certain node
kl exec deployments/alpine -- curl -sS http://10.3.10.3:9965/metrics > ./cilium-hubble-metrics.log

```
