
# Scraping external ETCD

```bash
# you need to have etcd client certificate in env folder
mkdir -p ./metrics/component-monitoring/etcd/external-etcd/env/
# if you set etcd up using ./docs/k8s/etcd/etcd.md, you can copy files from there
cp ./docs/k8s/etcd/env/ca.pem               ./metrics/component-monitoring/etcd/external-etcd/env/ca.crt
cp ./docs/k8s/etcd/env/etcd-client.pem      ./metrics/component-monitoring/etcd/external-etcd/env/client.crt
cp ./docs/k8s/etcd/env/etcd-client-key.pem  ./metrics/component-monitoring/etcd/external-etcd/env/client.key

# adjust list of addresses and ports for your environment
cat << EOF > ./metrics/component-monitoring/etcd/external-etcd/env/etcd-targets-patch.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-etcd
spec:
  staticConfigs:
  - labels:
      job: etcd
      cluster: k8s1-etcd
    targets:
    - k8s1-etcd1.k8s.lan:2379
    - k8s1-etcd2.k8s.lan:2379
    - k8s1-etcd3.k8s.lan:2379
EOF

# TODO is there a better namespace for this?
kl -n prometheus apply -k ./metrics/component-monitoring/etcd/external-etcd/
```
