
# etcd monitoring

This setup assumes that you already have Prometheus deployed.

You need to do a few things:

- Point prometheus to scrape etcd
- - [Built-in etcd](./built-in-etcd/readme.md)
- - [External etcd](./external-etcd/readme.md)
- Deploy prometheus rules and alerts
- Deploy grafana dashboard

References:
- https://etcd.io/docs/v3.5/metrics/
- https://etcd.io/docs/v3.1/metrics/etcd-metrics-v3.1.3.txt

# Common setup

```bash

kl -n prometheus apply -f ./metrics/component-monitoring/etcd/rules.yaml
kl -n prometheus apply -f ./metrics/component-monitoring/etcd/alerts.yaml

# dashboards should be in the grafana namespace
kl apply -k ./metrics/component-monitoring/etcd/dashboards/

```

# Updating dashboards

```bash
# remove min interval settings from all panels to force them to use the default data source min interval
sed -i '/\"interval\":/d' ./metrics/component-monitoring/etcd/dashboards/*.json
# remove id to avoid collisions
sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/component-monitoring/etcd/dashboards/*.json
# set dashboard refresh interval to auto
sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/component-monitoring/etcd/dashboards/*.json
```

# Manual metrics checking

```bash
etcdIp=k8s1-etcd1.k8s.lan
curl -sS \
  --cert ./metrics/component-monitoring/etcd/external-etcd/env/client.crt \
  --key ./metrics/component-monitoring/etcd/external-etcd/env/client.key \
  --cacert ./metrics/component-monitoring/etcd/external-etcd/env/ca.crt \
  https://$etcdIp:2379/metrics
```
