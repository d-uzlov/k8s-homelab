
# Proxy local

Same as [proxy](../proxy/readme.md) deployment but for `-local-` drivers.

`zfs-local-ephemeral-inline` is not compatible with proxy.

Non-local drivers are not compatible: use the main deployment for them.

References:
- https://github.com/democratic-csi/democratic-csi/pull/433

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi --version 0.15.0 > ./storage/democratic-csi-generic/default-values.yaml
```

```bash

helm template \
  dcsi \
  democratic-csi/democratic-csi \
  --version 0.15.0 \
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
nodeName=w2.k8s.lan
nodePod=$(kl -n pv-dem-local get pod -o name --field-selector spec.nodeName=$nodeName -l app.kubernetes.io/csi-role=node)
kl -n pv-dem-local logs $nodePod csi-driver > ./node.log
kl -n pv-dem-local logs $nodePod external-provisioner > ./node-external-provisioner.log

```

# Cleanup

```bash

kl delete -k ./storage/democratic-csi-generic/proxy-local/
kl delete ns pv-dem-local

```

# Storage classes

First you need to create configuration files for your storage classes:
- [Linux ZFS server](./generic-zfs-storage-classes.md)
- - [generic-zfs-server-setup.md](./generic-zfs-server-setup.md)
- [Truenas server](./truenas-storage-classes.md)

Don't forget to set up cluster nodes: [client-setup.md](./client-setup.md).

```bash

connections_folder=./storage/democratic-csi-generic/proxy-local/env/connections
file_args=()
for file in $(/usr/bin/ls $connections_folder/*); do
  echo adding $file
  file_args+=("--from-file=$file")
done
echo args ${file_args[@]}

kl create secret generic connections \
  --save-config \
  --dry-run=client \
  ${file_args[@]} \
  -o yaml | \
  kl -n pv-dem-local apply -f -

kl apply -f ./storage/democratic-csi-generic/proxy-local/env/storage-classes/

kl get sc

```
