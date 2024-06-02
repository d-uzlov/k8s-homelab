
# etcd monitoring

This setup assumes that you already have the KPS deployed.

# External ETCD case

```bash
mkdir -p ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/
# place certificates into external-etcd/env folder
# if you setup etcd using ./docs/k8s/etcd/etcd.md, you can copy files from there
cp ./docs/k8s/etcd/env/ca.pem               ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/ca.crt
cp ./docs/k8s/etcd/env/etcd-client.pem      ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/client.crt
cp ./docs/k8s/etcd/env/etcd-client-key.pem  ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/client.key

# init scrape config using your local environment info
cp \
  ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/scrape-external-etcd-template.yaml \
  ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/scrape-external-etcd.yaml
# adjust addresses and ports for your environment
cat << EOF >> ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/env/scrape-external-etcd.yaml
    targets:
    - k8s1-etcd1.k8s.lan:2379
    - k8s1-etcd2.k8s.lan:2379
    - k8s1-etcd3.k8s.lan:2379
EOF

kl apply -k ./metrics/kube-prometheus-stack/component-monitors/etcd/external-etcd/
```

# Setup for ETCD in static pods on master nodes

Master nodes have client etcd certificate, we need to extract it.

```bash
kl -n kube-system apply -f ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/cert-extractor.yaml

kl -n kube-system wait --for=condition=ready pods/cert-extractor

mkdir -p ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/env/
kl cp kube-system/cert-extractor:/mnt/ca.crt      ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/env/ca.crt
kl cp kube-system/cert-extractor:/mnt/client.crt  ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/env/client.crt
kl cp kube-system/cert-extractor:/mnt/client.key  ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/env/client.key

kl -n kube-system delete pod cert-extractor

kl apply -k ./metrics/kube-prometheus-stack/component-monitors/etcd/built-in-etcd/
```

Alternatively, you can copy etcd certs manually from any master node.

# Common setup

```bash
kl apply -f ./metrics/kube-prometheus-stack/component-monitors/etcd/grafana-dashboard.yaml
kl apply -f ./metrics/kube-prometheus-stack/component-monitors/etcd/rules.yaml
```
