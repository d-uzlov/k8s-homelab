
# deploy

```bash

# you need to have etcd client certificate in env folder
mkdir -p ./metrics/component-monitoring/k8s-control-plane/external/env/

# adjust list of addresses and ports for your environment

 cat << EOF > ./metrics/component-monitoring/k8s-control-plane/external/env/apiserver-targets-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-kube-apiserver
  namespace: prometheus
spec:
  staticConfigs:
  - labels:
      location: k8s-control-plane
    targets:
    - control-plane-1.k8s.lan:6443
    - control-plane-2.k8s.lan:6443
EOF

 cat << EOF > ./metrics/component-monitoring/k8s-control-plane/external/env/scheduler-targets-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-kube-scheduler
  namespace: prometheus
spec:
  staticConfigs:
  - labels:
      location: k8s-control-plane
    targets:
    - control-plane-1.k8s.lan:10259
    - control-plane-2.k8s.lan:10259
EOF

 cat << EOF > ./metrics/component-monitoring/k8s-control-plane/external/env/controller-manager-targets-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-kube-controller-manager
  namespace: prometheus
spec:
  staticConfigs:
  - labels:
      location: k8s-control-plane
    targets:
    - control-plane-1.k8s.lan:10257
    - control-plane-2.k8s.lan:10257
EOF

kl apply -k ./metrics/component-monitoring/k8s-control-plane/external/

```

# cleanup

```bash
kl delete -k ./metrics/component-monitoring/k8s-control-plane/external/
```

# manual metric checking:

```bash

bearer=$(kl -n prometheus get secrets prometheus-sa-token -o json | jq -r '.data.token' | base64 -d)
node=
curl -sS --insecure -H "Authorization: Bearer $bearer" https://$node:10259/metrics > ./kube-scheduler-metrics.log
echo | openssl s_client -showcerts -connect $node:10259 2> /dev/null | openssl x509 -text

```
