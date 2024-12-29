
# kube-prometheus-stack

If you want to upgrade, consult this: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

Different versions have different deploy commands.

References:
- https://technotim.live/posts/kube-grafana-prometheus/
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://github.com/prometheus-operator/kube-prometheus

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm search repo prometheus-community/kube-prometheus-stack --versions --devel | head
helm show values prometheus-community/kube-prometheus-stack --version 67.4.0 > ./metrics/kube-prometheus-stack/default-values.yaml
```

```bash
function remove_helm_junk() {
  sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '\|67.4.0|d' \
    -e '/^ *$/d' \
    -e '\|heritage\:|d' \
    -e '\|httpHeaders\:$|d'
}
function generateDeployment() {
  args=
  for arg in $*; do
    args="$args --set $arg"
  done
  helm template \
    kps \
    prometheus-community/kube-prometheus-stack \
    --version 67.4.0 \
    --values ./metrics/kube-prometheus-stack/values.yaml \
    $args \
    | remove_helm_junk
}

generateDeployment grafana.enabled=true             > ./metrics/kube-prometheus-stack/grafana/grafana.gen.yaml
mkdir -p ./metrics/kube-prometheus-stack/grafana/env/
cat <<EOF > ./metrics/kube-prometheus-stack/grafana/env/password-patch.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: kps-grafana
  namespace: kps-grafana
type: Opaque
stringData:
  admin-password: $(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
generateDeployment grafana.defaultDashboardsEnabled=true \
                   grafana.forceDeployDashboards=true \
                                                    > ./metrics/kube-prometheus-stack/grafana/grafana-default-dashboards.gen.yaml

generateDeployment kubeApiServer.enabled=true \
                   kubelet.enabled=true \
                   kubeControllerManager.enabled=true \
                   coreDns.enabled=false \
                   kubeScheduler.enabled=true       > ./metrics/kube-prometheus-stack/service-monitors.gen.yaml

generateDeployment kubeStateMetrics.enabled=true    > ./metrics/kube-prometheus-stack/kube-state-metrics/kubeStateMetrics.gen.yaml

generateDeployment nodeExporter.enabled=true        > ./metrics/kube-prometheus-stack/node-exporter/nodeExporter.gen.yaml

generateDeployment prometheusOperator.enabled=true \
                   prometheusOperator.admissionWebhooks.certManager.enabled=true \
                   namespaceOverride=kps-operator   > ./metrics/kube-prometheus-stack/prometheus-operator/prometheusOperator.gen.yaml

generateDeployment defaultRules.create=true \
                   namespaceOverride=kps-default-rules \
                                                    > ./metrics/kube-prometheus-stack/prometheus-default-rules/rules.gen.yaml
generateDeployment alertmanager.enabled=true        > ./metrics/kube-prometheus-stack/prometheus/alertmanager.gen.yaml
generateDeployment prometheus.enabled=true          > ./metrics/kube-prometheus-stack/prometheus/prometheus.gen.yaml

  # | sed -e 's/"interval":"1m"/"interval":"10s"/g'  \
```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

# Deploy

```bash
# customize your storage class and storage size request
mkdir -p ./metrics/kube-prometheus-stack/prometheus/env/
cat << EOF > ./metrics/kube-prometheus-stack/prometheus/env/patch.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: kps
  namespace: kps
spec:
  storage:
    volumeClaimTemplate:
      metadata:
        name: db
      spec:
        resources:
          requests:
            storage: 150Gi
        storageClassName: fast
EOF
```

```bash
kl apply -f ./metrics/kube-prometheus-stack/crd/ --server-side

kl create ns kps-ksm
kl label ns kps-ksm pod-security.kubernetes.io/enforce=baseline
kl apply -k ./metrics/kube-prometheus-stack/kube-state-metrics/
kl -n kps-ksm get pod -o wide

kl create ns kps-node-exporter
kl label ns kps-node-exporter pod-security.kubernetes.io/enforce=privileged
kl apply -k ./metrics/kube-prometheus-stack/node-exporter/
kl -n kps-node-exporter get pod -o wide

sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/kube-prometheus-stack/node-exporter/dashboards/*.json
sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/kube-prometheus-stack/node-exporter/dashboards/*.json
kl apply -k ./metrics/kube-prometheus-stack/node-exporter/dashboards/ --server-side

kl create ns kps-grafana
kl label ns kps-grafana pod-security.kubernetes.io/enforce=baseline
kl apply -k ./metrics/kube-prometheus-stack/grafana/
kl -n kps-grafana get pod -o wide

kl create ns kps-operator
kl label ns kps-operator pod-security.kubernetes.io/enforce=baseline
kl apply -k ./metrics/kube-prometheus-stack/prometheus-operator/
kl -n kps-operator get pod -o wide

kl create ns kps
kl label ns kps pod-security.kubernetes.io/enforce=baseline
kl apply -k ./metrics/kube-prometheus-stack/prometheus/
kl -n kps get pod -o wide

kl create ns kps-default-rules
kl label ns kps-default-rules pod-security.kubernetes.io/enforce=baseline
kl apply -f ./metrics/kube-prometheus-stack/service-monitors.gen.yaml
kl apply -k ./metrics/kube-prometheus-stack/prometheus-default-rules/
kl -n kps-default-rules get prometheusrule

# show list of all relevant prometheus configs
kl get prometheusrule -A
kl get servicemonitor -A
kl get podmonitor -A
kl get scrapeconfig -A
kl get probe -A

# wildcard ingress
kl label ns --overwrite kps copy-wild-cert=main
kl apply -k ./metrics/kube-prometheus-stack/prometheus-ingress-wildcard/
kl -n kps get ingress
kl apply -k ./metrics/kube-prometheus-stack/grafana-ingress-wildcard/
kl -n kps-grafana get ingress

# private gateway
kl apply -k ./metrics/kube-prometheus-stack/grafana-httproute/
kl -n kps-grafana get httproute grafana
kl -n kps-grafana describe httproute grafana
kl apply -k ./metrics/kube-prometheus-stack/prometheus-httproute/
kl -n kps get httproute prometheus
kl -n kps describe httproute prometheus

kl -n kps exec sts/prometheus-kps -- df -h | grep /prometheus\$
```

Default grafana user is `admin`.
Look up admin password in [password-patch.yaml](./grafana/env/password-patch.yaml).

Don't forget to deploy additional dashboards:
- [k8s](./component-monitors/k8s/readme.md)
- [etcd](./component-monitors/etcd/readme.md)
- [proxmox](./component-monitors/proxmox/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/kube-state-metrics/
kl delete -k ./metrics/kube-prometheus-stack/node-exporter/dashboards/
kl delete -k ./metrics/kube-prometheus-stack/node-exporter/
kl delete -k ./metrics/kube-prometheus-stack/grafana/
kl delete -k ./metrics/kube-prometheus-stack/prometheus-default-rules/
kl delete -k ./metrics/kube-prometheus-stack/prometheus-operator/
kl delete -k ./metrics/kube-prometheus-stack/prometheus/
kl delete -k ./metrics/kube-prometheus-stack/
kl delete ns kps-default-rules
kl delete ns kps-grafana
kl delete ns kps
kl delete ns kps-operator
kl delete ns kps-ksm
kl delete ns kps-node-exporter
kl delete -f ./metrics/kube-prometheus-stack/crd/
```

# kube-controller-manager and kube-scheduler metrics

If you want to see metrics from kube-controller-manager and kube-scheduler,
you need to change its configs to bind to node IP instead of localhost.

If you use kubeadm for cluster setup,
you can edit kubeadm config to make changes persistent:

```bash
kl edit -n kube-system cm kubeadm-config
```

Make sure you have the following additional `extraArgs` values listed:

```yaml
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0
scheduler:
  extraArgs:
    bind-address: 0.0.0.0
```

After you change kubeadm-config, you need to apply new config on all master nodes:

```bash
sudo kubeadm upgrade node
```

# TODO

Maybe it's better to change default k8s metrics polling interval.
Even if prometheus polls metrics each second,
k8s metrics are updated only once every 10 seconds, or slower.

Keywords: `housekeeping-interval`.

# Metric manipulations

```bash
# delete a metric
prometheus_ingress=$(kl -n kps get ingress   prometheus -o go-template --template "{{ (index .spec.rules 0).host}}")
prometheus_ingress=$(kl -n kps get httproute prometheus -o go-template --template "{{ (index .spec.hostnames 0) }}")
# metric name
metric=
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series?match[]=$metric"
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series?match[]={__name__=~\"$metric\"}" --data-urlencode "start=2024-12-29T05:16:42+07:00" --data-urlencode "end=2024-12-29T05:35:45+07:00"
# run clean_tombstones to actually clean data
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/clean_tombstones"

# list all metrics that have specified labels
# source: https://stackoverflow.com/questions/70301131/how-to-get-all-metric-names-from-prometheus-server-filtered-by-a-particular-labe
curl -X GET -G "https://$prometheus_ingress/api/v1/label/__name__/values" --data-urlencode 'match[]={__name__=~".+", job="kubelet"}'

# show current config
kl -n kps exec statefulsets/prometheus-kps -it -- cat /etc/prometheus/config_out/prometheus.env.yaml

# generate missing past metrics for a new recording rule
#     enter the prometheus container
kl -n kps exec statefulsets/prometheus-kps -it -- sh
#     inside the container: find recording rule file and run promtool
ls -la /etc/prometheus/rules/prometheus-kps-rulefiles-0/
# Be careful! Do not overlap time period with existing data!
promtool tsdb create-blocks-from rules --start 2024-05-29T21:33:40+07:00 --end 2024-06-11T14:40:40+07:00 --output-dir=. --eval-interval=10s /etc/prometheus/rules/prometheus-kps-rulefiles-0/kps-default-rules-etcd-recording-f515cf3e-c48e-4ff4-ab43-d997c9aa4825.yaml

# to delete _all_ data from prometheus, delete /prometheus contents and restart prometheus
# rm -rf will fail, it's OK, it just can't delete some of the special files
kl -n kps exec statefulsets/prometheus-kps -it -- rm -rf /prometheus
kl -n kps delete pod prometheus-kps-0
kl -n kps get pod -o wide
```

References:
- https://faun.pub/how-to-drop-and-delete-metrics-in-prometheus-7f5e6911fb33
- https://prometheus.io/docs/prometheus/latest/storage/#backfilling-for-recording-rules

# Manual metric checking

```bash
bearer=$(kl -n kps exec sts/prometheus-kps -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl get node -o wide
nodeIp=
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/cadvisor
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/probes

# watch for some metric
while true; do
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/cadvisor | grep immich-postgresql-0 | grep container_fs_writes_bytes_total | grep container=\"postgresql\" | sed "s/^/$(date +%H-%M-%S) /" >> ./cadvisor.log
sleep 5
done

kl -n kube-system describe svc kps-coredns
corednsIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$corednsIp:9153/metrics

kl describe svc kubernetes
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:6443/metrics

kl -n kube-system describe svc kps-kube-controller-manager
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10257/metrics

kl -n kube-system describe svc kps-kube-scheduler
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10259/metrics

kl -n kps-node-exporter describe svc kps-prometheus-node-exporter
curl -k -H "Authorization: Bearer $bearer" http://$nodeIp:9100/metrics

kl -n kps-grafana describe svc kps-grafana
grafanaIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$grafanaIp:3000/metrics

kl -n kps describe svc alertmanager-operated
alertManagerIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$alertManagerIp:9093/metrics
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$alertManagerIp:8080/metrics

kl -n kps describe svc prometheus-operated
prometheusIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$prometheusIp:9090/metrics
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$prometheusIp:8080/metrics

kl -n kps-operator describe svc prometheus-operator
prometheusOperatorIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" https://$prometheusOperatorIp:10250/metrics

kl -n kps-ksm describe svc kube-state-metrics
kubeStateMetricsIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$kubeStateMetricsIp:8080/metrics
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$kubeStateMetricsIp:8081/metrics
```

# TODO

cadvisor metrics seem to have issues:
- large cardinality?
- values are duplicated: container==name and container==""

high cardinality:
- prober_probe_duration_seconds

Need to check out kubelet metrics.
