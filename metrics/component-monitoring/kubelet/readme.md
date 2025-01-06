
# kubelet

Kubelet provides all of the container metrics,
so it can be considered mandatory for deployment.

```bash

mkdir -p ./metrics/component-monitoring/kubelet/env/
clusterName=
cat << EOF > ./metrics/component-monitoring/kubelet/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/-
  value:
    targetLabel: cluster
    replacement: $clusterName
EOF

kl apply -k ./metrics/component-monitoring/kubelet/
```

For alerts and dashboards to work properly,
you need to also deploy [kube-state-metrics](../../../kube-state-metrics/readme.md).

Don't forget to deploy grafana dashboards: [dashboards](./dashboards/readme.md).

# Cleanup

```bash
kl delete -k ./metrics/component-monitoring/kubelet/
```

# Manual metric checking

```bash
bearer=$(kl -n prometheus exec sts/prometheus-main -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl get node -o wide
nodeIp=10.3.10.3
# these metrics are not monitored here
curl -sS --insecure -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics
# main container metrics
curl -sS --insecure -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/cadvisor
# liveness/readiness probe statistics
curl -sS --insecure -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/probes

# watch for some metric
while true; do
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/cadvisor | grep immich-postgresql-0 | grep container_fs_writes_bytes_total | grep container=\"postgresql\" | sed "s/^/$(date +%H-%M-%S) /" >> ./cadvisor.log
sleep 5
done

```
