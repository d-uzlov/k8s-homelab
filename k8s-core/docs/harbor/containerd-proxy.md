
# Containerd setup for Harbor proxy

Here we will make containerd try to connect to the local Harbor instance,
and fall back to the original registry if Harbor is unavailable.

Prerequisites:
- [Harbor](./harbor.md)

References:
- https://github.com/containerd/containerd/blob/main/docs/hosts.md
- https://github.com/goharbor/harbor/issues/18530

# Enable registry mirrors

Should be done once for each node.

```bash

containerd_node=

# enable registry mirrors in containerd
ssh $containerd_node sudo bash -s - << EOF &&
sed -i '/\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.registry\]$/{n;s|config_path = ""|config_path = "/etc/containerd/certs.d"|;}' /etc/containerd/config.toml
EOF
ssh $containerd_node sudo systemctl restart containerd.service

# copy the ca file used by harbor into the node
ssh $containerd_node sudo mkdir -p /etc/certs/ &&
ssh $containerd_node sudo tee '>' /dev/null < ./k8s-core/docsharbor/env/ca.crt /etc/certs/harbor-ca.crt

```

# Test connection

Force connection through harbor, so that it fails if something isn't right.

```bash

containerd_node=

registries="docker.io ghcr.io quay.io registry.k8s.io"
for registry in $registries; do
  ssh $containerd_node sudo mkdir -p /etc/containerd/certs.d/$registry/
  ssh $containerd_node sudo tee /etc/containerd/certs.d/$registry/hosts.toml << EOF
server = "https://$harbor_address/v2/$registry/"
ca = "/etc/certs/harbor-ca.crt"
override_path = true
[host."https://$harbor_address/v2/$registry/"]
  capabilities = ["pull", "resolve"]
  ca = "/etc/certs/harbor-ca.crt"
  override_path = true
EOF
done

# check that cache works
# you shouldn't see any errors here,
# and "Quota used" in the Harbor web UI should increase after the pull
# you can also find the image in the registry after Harbor indexes it
ssh $containerd_node sudo crictl pull docker.io/alpine:20240315
ssh $containerd_node sudo crictl pull ghcr.io/screego/server:1.10.1
ssh $containerd_node sudo crictl pull quay.io/cilium/alpine-curl:v1.8.0
ssh $containerd_node sudo crictl pull registry.k8s.io/metrics-server/metrics-server:v0.6.2

```

# Set up mirrors / proxies

Here we setup mirrors with the fallback to the original registry when Harbor is not available.

```bash

containerd_node=

registries="docker.io ghcr.io quay.io registry.k8s.io"
for registry in $registries; do
  ssh $containerd_node sudo mkdir -p /etc/containerd/certs.d/$registry/
  ssh $containerd_node sudo tee /etc/containerd/certs.d/$registry/hosts.toml << EOF
[host."https://$harbor_address/v2/$registry/"]
  capabilities = ["pull", "resolve"]
  ca = "/etc/certs/harbor-ca.crt"
  override_path = true
EOF
done

```
