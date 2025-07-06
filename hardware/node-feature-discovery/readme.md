
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
helm show values nfd/node-feature-discovery --version 0.17.3 > ./hardware/node-feature-discovery/default-values.yaml
```

```bash

crd_url=https://github.com/kubernetes-sigs/node-feature-discovery/raw/v0.17.3/deployment/helm/node-feature-discovery/crds/nfd-api-crds.yaml
curl -fsSL "$crd_url" --output ./hardware/node-feature-discovery/crd.yaml

helm template \
  nfd \
  nfd/node-feature-discovery \
  --version 0.17.3 \
  --namespace hw-nfd \
  --values ./hardware/node-feature-discovery/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./hardware/node-feature-discovery/nfd.gen.yaml
yq 'select(.metadata.name == "nfd-prune")' ./hardware/node-feature-discovery/nfd.gen.yaml > ./hardware/node-feature-discovery/nfd-prune.gen.yaml
yq 'select(.metadata.name != "nfd-prune")' -i ./hardware/node-feature-discovery/nfd.gen.yaml
yamlfmt ./hardware/node-feature-discovery/nfd.gen.yaml ./hardware/node-feature-discovery/nfd-prune.gen.yaml

```

# Deploy

```bash

kl apply -f ./hardware/node-feature-discovery/crd.yaml --server-side

kl create ns hw-nfd
kl label ns hw-nfd pod-security.kubernetes.io/enforce=privileged

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
kl apply -f ./hardware/node-feature-discovery/nfd-prune.gen.yaml
kl -n hw-nfd get pod -o wide
kl delete -f ./hardware/node-feature-discovery/nfd-prune.gen.yaml
kl delete -f ./hardware/node-feature-discovery/crd.yaml
kl delete ns hw-nfd
```
