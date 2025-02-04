
# Proxy driver

In democratic-csi there are drivers
that can provision and mount volumes.
Usually you deploy an instance of democratic-csi
with a fixed config to use a driver.
If you need to connect to 2 different servers,
or use different protocols, or 2 different datasets,
you need to deploy a second instance of democratic-csi.

`proxy` driver solves this issue. It doesn't connect to any server.
Instead it dynamically reads config from the cluster
and allows you to use many drivers with many configs
via the same instance of democratic-csi.

Its contract is as following:
- Only 1 value is required in the config: `driver: proxy`
- Other values are allowed, and will be used as default values for other drivers
- Driver configs are located via `csi.storage.k8s.io/provisioner-secret-name` and other parameters
- All keys from the secret starting with `config-` are sorted and merged info real driver config on top of the main config
- Each storage class can have a completely different config

In this deployment we configure `zfs-generic-*` drivers,
but the proxy driver should be compatible with almost all drivers
except the `zfs-local-ephemeral-inline`.

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
  --values ./storage/democratic-csi-generic/proxy/values.yaml \
  --namespace pv-dcsi \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|^#|d' \
  > ./storage/democratic-csi-generic/proxy/deployment.gen.yaml

```

# Deploy

```bash
kl create ns pv-dcsi
kl label ns pv-dcsi pod-security.kubernetes.io/enforce=privileged

kl -n pv-dcsi apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dcsi apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -k ./storage/democratic-csi-generic/proxy/
kl -n pv-dcsi get pod -o wide

# view logs if something does not work
kl -n pv-dcsi logs deployments/dcsi-controller csi-driver > ./controller.log
kl -n pv-dcsi logs deployments/dcsi-controller external-provisioner > ./controller-external-provisioner.log

# if some pod is failing to get PVC attached,
# look at logs of dcsi node pod
# get node name from the failing workload pod
nodeName=
nodePod=$(kl -n pv-dcsi get pod -o name --field-selector spec.nodeName=$nodeName -l app.kubernetes.io/csi-role=node)
kl -n pv-dcsi logs $nodePod csi-driver > ./node.log
```

# Cleanup

```bash
kl delete -k ./storage/democratic-csi-generic/dcsi/
kl delete ns pv-dcsi
```
