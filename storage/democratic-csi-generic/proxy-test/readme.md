
# Proxy test

This deployment is meant for testing only.
There is nothing special or unique about it.

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update democratic-csi
helm search repo democratic-csi/democratic-csi --versions --devel | head
helm show values democratic-csi/democratic-csi --version 0.14.7 > ./storage/democratic-csi-generic/default-values.yaml
```

```bash

image=docker.io/daniluzlov/k8s-snippets:dcsi-proxy-topology-v13
helm template \
  dcsi \
  democratic-csi/democratic-csi \
  --version 0.14.7 \
  --values ./storage/democratic-csi-generic/proxy-test/values.yaml \
  --set controller.driver.image=$image \
  --set node.driver.image=$image \
  --namespace pv-dem-test \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|^#|d' \
  > ./storage/democratic-csi-generic/proxy-test/deployment.gen.yaml

```

# Deploy

```bash

kl create ns pv-dem-test
# all CSI plugins need access to host system
kl label ns pv-dem-test pod-security.kubernetes.io/enforce=privileged

kl -n pv-dem-test apply -f ./network/network-policies/deny-ingress.yaml
kl -n pv-dem-test apply -f ./network/network-policies/allow-same-namespace.yaml

# config secret must be created before main deployment
kl -n pv-dem-test create secret generic connections
kl apply -k ./storage/democratic-csi-generic/proxy-test/
kl -n pv-dem-test get pod -o wide

# check currently existing connections
kl -n pv-dem-test describe secrets connections

# view logs if something does not work
kl -n pv-dem-test logs deployments/dem-test-controller csi-driver > ./controller.log
kl -n pv-dem-test logs deployments/dem-test-controller external-provisioner > ./controller-external-provisioner.log

# if some pod is failing to get PVC attached,
# look at logs of dcsi node pod
# get node name from the failing workload pod
nodeName=n100.k8s.lan
nodePod=$(kl -n pv-dem-test get pod -o name --field-selector spec.nodeName=$nodeName -l app.kubernetes.io/csi-role=node)
kl -n pv-dem-test logs $nodePod csi-driver > ./node.log

```

# Cleanup

```bash

kl delete -k ./storage/democratic-csi-generic/proxy-test/
kl delete ns pv-dem-test

```

# Storage classes

First you need to create configuration files for your storage classes:
- [Linux ZFS server](./generic-zfs-storage-classes.md)
- - [generic-zfs-server-setup.md](./generic-zfs-server-setup.md)
- [Truenas server](./truenas-storage-classes.md)

Don't forget to set up cluster nodes: [client-setup.md](./client-setup.md).

```bash

 connections_folder=./storage/democratic-csi-generic/proxy-test/env/connections/
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
  kl -n pv-dem-test apply -f -

kl apply -f ./storage/democratic-csi-generic/proxy-test/env/storage-classes/

kl get sc

```
