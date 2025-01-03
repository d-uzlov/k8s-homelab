
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

generateDeployment defaultRules.create=true \
                   namespaceOverride=kps-default-rules \
                                                    > ./metrics/kube-prometheus-stack/prometheus-default-rules/rules.gen.yaml
generateDeployment alertmanager.enabled=true        > ./metrics/kube-prometheus-stack/prometheus/alertmanager.gen.yaml

  # | sed -e 's/"interval":"1m"/"interval":"10s"/g'  \
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
kl apply -k ./metrics/kube-prometheus-stack/prometheus-default-rules/
kl -n kps-default-rules get prometheusrule

```

Don't forget to deploy additional dashboards:
- [k8s](./component-monitors/k8s/readme.md)
- [etcd](./component-monitors/etcd/readme.md)
- [proxmox](./component-monitors/proxmox/readme.md)

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/grafana/
kl delete -k ./metrics/kube-prometheus-stack/prometheus-default-rules/
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

kl -n kps describe svc alertmanager-operated
alertManagerIp=
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$alertManagerIp:9093/metrics
kl exec deployments/alpine -- curl -k -H "Authorization: Bearer $bearer" http://$alertManagerIp:8080/metrics
```

# Alertmanager setup

References:
- Obtain telegram bot token and chat ID: https://gist.github.com/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a

```bash
# first send a message to bot, to create a private chat with the bot
botToken=
curl https://api.telegram.org/bot$botToken/getUpdates
# look for chat id in the output

mkdir -p ./metrics/kube-prometheus-stack/prometheus/env/telegram/
cat << EOF > ./metrics/kube-prometheus-stack/prometheus/env/telegram/telegram-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  namespace: kps
  name: telegram-bot-token
type: Opaque
stringData:
  token: 1234567890:qwertyuiopasdfghj_klzxcvbnmqwertyui
EOF

cat << EOF > ./metrics/kube-prometheus-stack/prometheus/env/telegram/alert-manager-telegram.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  namespace: kps
  name: telegram
  labels:
    alert: main
spec:
  route:
    # groupBy: [ 'job' ]
    groupBy: [ 'alertname' ]
    # groupBy: [ '...' ] # '...' disables grouping
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
    receiver: telegram
    matchers:
    - name: severity
      value: none
      matchType: '!='
  receivers:
  - name: telegram
    telegramConfigs:
    - apiURL: https://api.telegram.org
      botToken:
        name: telegram-bot-token
        key: token
      chatID: 123456789
      message: |
        {{ if gt (len .Alerts.Firing) 0 }}
        📢 {{ (index .Alerts.Firing 0).Labels.alertname}}
        {{ range .Alerts.Firing }}
        🚨 {{ .Annotations.description }}
        {{ end }}
        {{ end }}
        {{ if gt (len .Alerts.Resolved) 0 }}
        🍀 {{ (index .Alerts.Resolved 0).Labels.alertname}}
        {{ range .Alerts.Resolved }}
        ✔️ Solved: {{ .Annotations.description }}
        {{ end }}
        {{ end }}
  # inhibitRules:
  # - sourceMatch:
  #   - name: severity
  #     value: critical
  #     matchType: '!='
  #   targetMatch:
  #   - name: severity
  #     value: warning
  #     matchType: '='
  #   equal: [ 'alertname', 'dev', 'instance' ]
EOF

kl apply -k ./metrics/kube-prometheus-stack/prometheus/env/telegram/
kl -n kps describe AlertmanagerConfig telegram
```

# TODO

cadvisor high cardinality:
- prober_probe_duration_seconds

Need to check out kubelet metrics.
