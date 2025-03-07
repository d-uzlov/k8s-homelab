
# Proxy driver

In democratic-csi there are drivers
that can provision and mount volumes.
Usually you deploy an instance of democratic-csi
with a fixed config to use a driver.
If you need to connect to 2 different servers,
or use different protocols, or 2 different datasets,
you need to deploy a second instance of democratic-csi.

`proxy` driver solves this issue. It doesn't immediately connect to any server.
Instead it dynamically reads config from the cluster
and allows you to use many drivers with many configs
via a single instance of democratic-csi.

Proxy config format:

```yaml
driver: proxy

proxy:
  configFolder: /mnt/connections/
```

Other values are allowed, and will be used as default values for other drivers.

Other driver config is located in `proxy.configFolder`.

Storage class must have `parameters.connection` set to file name in the config folder (without `.yaml` extension).

`zfs-local-ephemeral-inline`, `objectivefs` are not compatible with proxy.

References:
- https://github.com/d-uzlov/democratic-csi/tree/proxy-driver

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi --version 0.14.7 > ./storage/democratic-csi-generic/default-values.yaml
```

```bash

helm template \
  dcsi \
  democratic-csi/democratic-csi \
  --version 0.14.7 \
  --values ./storage/democratic-csi-generic/proxy-local/values.yaml \
  --namespace pv-dem-local \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|^#|d' \
  > ./storage/democratic-csi-generic/proxy-local/deployment.gen.yaml

```

# Deploy

```bash

kl create ns pv-dem-local
# all CSI plugins need access to host system
kl label ns pv-dem-local pod-security.kubernetes.io/enforce=privileged

kl -n pv-dem-local apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dem-local apply -f ./network/network-policies/allow-same-namespace.yaml

# config secret must be created before main deployment
kl -n pv-dem-local create secret generic connections
kl apply -k ./storage/democratic-csi-generic/proxy-local/
kl -n pv-dem-local get pod -o wide
kl -n pv-dem-local get csistoragecapacity

# view logs if something does not work
nodeName=w1.k8s.lan
nodePod=$(kl -n pv-dem-local get pod -o name --field-selector spec.nodeName=$nodeName -l app.kubernetes.io/csi-role=node)
kl -n pv-dem-local logs $nodePod csi-driver > ./node.log
kl -n pv-dem-local logs $nodePod external-provisioner > ./node-external-provisioner.log

```

# Cleanup

```bash

kl delete -k ./storage/democratic-csi-generic/proxy-local/
kl delete ns pv-dem-local

```
