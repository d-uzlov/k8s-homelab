
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
