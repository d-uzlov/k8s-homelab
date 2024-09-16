
# Node Feature Discovery

References:
- https://github.com/kubernetes-sigs/node-feature-discovery#node-feature-discovery
- https://kubernetes-sigs.github.io/node-feature-discovery/master/deployment/helm.html

# Generate config

You only need to do this when updating the app.

```bash
helm repo add nfd https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update nfd
helm search repo nfd/node-feature-discovery --versions --devel | head
helm show values nfd/node-feature-discovery > ./hardware/node-feature-discovery/default-values.yaml
```

```bash
helm template \
  nfd \
  nfd/node-feature-discovery \
  --version 0.16.4 \
  --namespace hw-nfd \
  --values ./hardware/node-feature-discovery/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./hardware/node-feature-discovery/nfd.gen.yaml
```

```bash
crd_url=https://github.com/kubernetes-sigs/node-feature-discovery/raw/v0.16.4/deployment/helm/node-feature-discovery/crds/nfd-api-crds.yaml
curl -fsSL "$crd_url" --output ./hardware/node-feature-discovery/crd.yaml
```

# Deploy

```bash
kl apply -f ./hardware/node-feature-discovery/crd.yaml --server-side

kl create ns hw-nfd
kl apply -f ./hardware/node-feature-discovery/nfd.gen.yaml

kl -n hw-nfd get pod -o wide

# check that nfd deployment updated node labels
kl describe node | grep feature.node.kubernetes.io
kl describe node | grep pci
```

List of PCI vendor IDs:
- https://admin.pci-ids.ucw.cz/read/PC?restrict=

# Cleanup

```bash
kl delete -f ./hardware/node-feature-discovery/nfd.gen.yaml
kl delete -f ./hardware/node-feature-discovery/crd.yaml
kl delete ns hw-nfd
```
