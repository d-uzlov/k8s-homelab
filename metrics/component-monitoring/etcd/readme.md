
# etcd monitoring

This setup assumes that you already have the KPS deployed.

References:
- https://etcd.io/docs/v3.5/metrics/
- https://etcd.io/docs/v3.1/metrics/etcd-metrics-v3.1.3.txt

# External ETCD case

```bash
mkdir -p ./metrics/component-monitoring/etcd/external-etcd/env/
# place certificates into external-etcd/env folder
# if you setup etcd using ./docs/k8s/etcd/etcd.md, you can copy files from there
cp ./docs/k8s/etcd/env/ca.pem               ./metrics/component-monitoring/etcd/external-etcd/env/ca.crt
cp ./docs/k8s/etcd/env/etcd-client.pem      ./metrics/component-monitoring/etcd/external-etcd/env/client.crt
cp ./docs/k8s/etcd/env/etcd-client-key.pem  ./metrics/component-monitoring/etcd/external-etcd/env/client.key

# init scrape config using your local environment info
cp \
  ./metrics/component-monitoring/etcd/external-etcd/scrape-external-etcd-template.yaml \
  ./metrics/component-monitoring/etcd/external-etcd/env/scrape-external-etcd.yaml
# adjust addresses and ports for your environment
cat << EOF >> ./metrics/component-monitoring/etcd/external-etcd/env/scrape-external-etcd.yaml
    targets:
    - k8s1-etcd1.k8s.lan:2379
    - k8s1-etcd2.k8s.lan:2379
    - k8s1-etcd3.k8s.lan:2379
EOF

kl apply -k ./metrics/component-monitoring/etcd/external-etcd/
```

# Setup for ETCD in static pods on master nodes

Master nodes have client etcd certificate, we need to extract it.

```bash
kl -n kube-system apply -f ./metrics/component-monitoring/etcd/built-in-etcd/cert-extractor.yaml

kl -n kube-system wait --for=condition=ready pods/cert-extractor

mkdir -p ./metrics/component-monitoring/etcd/built-in-etcd/env/
kl cp kube-system/cert-extractor:/mnt/ca.crt      ./metrics/component-monitoring/etcd/built-in-etcd/env/ca.crt
kl cp kube-system/cert-extractor:/mnt/client.crt  ./metrics/component-monitoring/etcd/built-in-etcd/env/client.crt
kl cp kube-system/cert-extractor:/mnt/client.key  ./metrics/component-monitoring/etcd/built-in-etcd/env/client.key

kl -n kube-system delete pod cert-extractor

kl apply -k ./metrics/component-monitoring/etcd/built-in-etcd/
```

Alternatively, you can copy etcd certs manually from any master node.

# Updating dashboards

```bash
# remove id to avoid collisions
sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/etcd/dashboards/dashboard.json
# set dashboard refresh interval to auto
sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/etcd/dashboards/dashboard.json
```

# Common setup

```bash
kl apply -f ./metrics/component-monitoring/etcd/rules.yaml
kl apply -f ./metrics/component-monitoring/etcd/alerts.yaml

kl apply -k ./metrics/component-monitoring/etcd/dashboards/
```

# Metrics

```bash
etcdIp=k8s1-etcd1.k8s.lan
curl \
  --cert ./metrics/component-monitoring/etcd/external-etcd/env/client.crt \
  --key ./metrics/component-monitoring/etcd/external-etcd/env/client.key \
  --cacert ./metrics/component-monitoring/etcd/external-etcd/env/ca.crt \
  https://$etcdIp:2379/metrics
```
