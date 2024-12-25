(
cd ./metrics/kube-prometheus-stack/crd/
rm ./*.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
wget https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.79.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
)
