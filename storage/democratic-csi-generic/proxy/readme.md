
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

Local drivers are not compatible to this deployment. Use special [proxy-local](../proxy-local/readme.md)
`objectivefs` are not compatible with proxy.

References:
- https://github.com/d-uzlov/democratic-csi/tree/proxy-driver
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
  --values ./storage/democratic-csi-generic/proxy/values.yaml \
  --namespace pv-dem \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|^#|d' \
  > ./storage/democratic-csi-generic/proxy/deployment.gen.yaml

```

# Deploy

```bash

kl create ns pv-dem
# all CSI plugins need access to host system
kl label ns pv-dem pod-security.kubernetes.io/enforce=privileged

kl -n pv-dem apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dem apply -f ./network/network-policies/allow-same-namespace.yaml

# config secret must be created before main deployment
kl -n pv-dem create secret generic connections
kl apply -k ./storage/democratic-csi-generic/proxy/
kl -n pv-dem get pod -o wide

# view logs if something does not work
kl -n pv-dem logs deployments/dem-controller csi-driver > ./controller.log
kl -n pv-dem logs deployments/dem-controller external-provisioner > ./controller-external-provisioner.log

# if some pod is failing to get PVC attached,
# look at logs of dcsi node pod
# get node name from the failing workload pod
nodeName=w1.k8s.lan
nodePod=$(kl -n pv-dem get pod -o name --field-selector spec.nodeName=$nodeName -l app.kubernetes.io/csi-role=node)
kl -n pv-dem logs $nodePod csi-driver > ./node.log

```

# Cleanup

```bash

kl delete -k ./storage/democratic-csi-generic/proxy/
kl delete ns pv-dem

```

# Storage classes

First you need to create configuration files for your storage classes:
- [Linux ZFS server](./generic-zfs-storage-classes.md)
- - [generic-zfs-server-setup.md](./generic-zfs-server-setup.md)
- [Truenas server](./truenas-storage-classes.md)

Don't forget to set up cluster nodes: [client-setup.md](./client-setup.md).

```bash

connections_folder=./storage/democratic-csi-generic/proxy/env/connections
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
  kl -n pv-dem apply -f -

kl apply -f ./storage/democratic-csi-generic/proxy/env/storage-classes/

kl get sc

```
