
# 3x-ui

References:
- https://github.com/MHSanaei/3x-ui

# local settings

```bash

mkdir -p ./network/xray/env/

storage_class=tulip-nfs
size=10Mi

 cat << EOF > ./network/xray/env/3x-ui.yaml
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: 3xui
  namespace: vpn-xray
spec:
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: config
    spec:
      storageClassName: $storage_class
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: $size
EOF

panel_path=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
 cat << EOF > ./network/xray/env/config.env
panelBasePath=/$panel_path/
metrics_address=https://127.0.0.1:12053/$panel_path/
EOF

clusterName=
 cat << EOF > ./network/xray/env/patch-location-tag.yaml
- op: add
  path: /spec/podMetricsEndpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

# when pod restarts, login credentials will reset to values from pass.env
 cat << EOF > ./network/xray/env/pass.env
username=admin
password=admin
EOF

mkdir -p ./network/xray/httproute-public/env/
cp ./network/xray/httproute-public/httproute.template.yaml ./network/xray/httproute-public/env/httproute.yaml

# generate a prefix
echo $(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)

```

Fill in random prefixes in `./network/xray/httproute-public/env/httproute.yaml`.

# deploy

```bash

kl create ns vpn-xray
kl label ns vpn-xray pod-security.kubernetes.io/enforce=baseline

kl apply -k ./network/xray/

kl -n vpn-xray get pvc
kl -n vpn-xray get pod -o wide

kl apply -k ./network/xray/httproute-protected/
kl apply -k ./network/xray/httproute-public/
kl -n vpn-xray get htr

```

# cleanup

```bash

kl delete -k ./network/xray/httproute-protected/
kl delete -k ./network/xray/
kl delete ns vpn-xray

```

# snippets

```bash

kl -n vpn-xray exec 3xui-0 -it -- sh
kl -n vpn-xray exec 3xui-0 -it -- x-ui

# check current panel path
kl -n vpn-xray exec 3xui-0 -- /app-tmp/x-ui setting -show

```
