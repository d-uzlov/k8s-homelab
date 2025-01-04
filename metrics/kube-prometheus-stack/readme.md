
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
    -e '\|release: kps|d' \
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

generateDeployment grafana.defaultDashboardsEnabled=true \
                   grafana.forceDeployDashboards=true \
                                                    > ./metrics/kube-prometheus-stack/grafana/grafana-default-dashboards.gen.yaml

generateDeployment kubeApiServer.enabled=true \
                   kubelet.enabled=true \
                   kubeControllerManager.enabled=true \
                   coreDns.enabled=false \
                   kubeScheduler.enabled=true       > ./metrics/kube-prometheus-stack/service-monitors.gen.yaml

```

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

# Deploy

```bash
# deploys default grafana dashboards from kps
kl apply -k ./metrics/kube-prometheus-stack/grafana/

kl create ns kps-default-rules
kl label ns kps-default-rules pod-security.kubernetes.io/enforce=baseline
kl apply -f ./metrics/kube-prometheus-stack/service-monitors.gen.yaml
kl -n kps-default-rules get prometheusrule

```

Don't forget to deploy additional dashboards:
- [k8s](./component-monitors/k8s/readme.md)
- [etcd](./component-monitors/etcd/readme.md)
- [proxmox](./component-monitors/proxmox/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/grafana/
kl delete ns kps-default-rules
kl delete ns kps-grafana
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

# Manual metric checking

```bash
bearer=$(kl -n kps exec sts/prometheus-kps -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kl get node -o wide
nodeIp=10.3.10.3
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/cadvisor
curl -k -H "Authorization: Bearer $bearer" https://$nodeIp:10250/metrics/probes > ./probe.log

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

kl -n kps-grafana describe svc kps-grafana
grafanaIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$grafanaIp:3000/metrics
```

# TODO

cadvisor high cardinality:
- prober_probe_duration_seconds

Need to check out kubelet metrics.
