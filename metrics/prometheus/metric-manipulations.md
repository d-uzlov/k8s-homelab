
# Metric manipulations

```bash
# delete a metric
prometheus_ingress=$(kl -n prometheus get ingress   prometheus -o go-template --template "{{ (index .spec.rules 0).host}}")
prometheus_ingress=$(kl -n prometheus get httproute prometheus -o go-template --template "{{ (index .spec.hostnames 0) }}")

# start and end parameters are optional.
# By default prometheus will delete time series from all time.
# delete everything from selected time range
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series" --data-urlencode 'match[]={__name__=~".*"}' --data-urlencode "start=2025-01-02T02:04:30+07:00" --data-urlencode "end=2025-01-02T02:05:47+07:00"
# delete all metrics having a certain label
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series" --data-urlencode 'match[]={service="kps-kubelet"}' --data-urlencode "start=2025-01-02T02:00:30+07:00" --data-urlencode "end=2025-01-02T09:40:29+07:00"
# delete selected time range for a metric
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series" --data-urlencode '?match[]=metric_name' --data-urlencode "start=2024-12-29T05:16:42+07:00" --data-urlencode "end=2024-12-29T05:35:45+07:00"
# delete time series within time range
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series?match[]=container_cpu_usage_seconds_total:with_pod_info" --data-urlencode "start=2025-01-02T02:00:11+07:00" --data-urlencode "end=2025-01-02T09:23:12+07:00"
# delete time series by name regex with additional labels filter
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series" --data-urlencode 'match[]={__name__=~"container_network_.*",interface=~"lxc.*"}'
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/delete_series" --data-urlencode 'match[]={__name__=~"node_network_.*",device=~"lxc.*"}'
# run clean_tombstones to actually clean data
curl -X POST -g "https://$prometheus_ingress/api/v1/admin/tsdb/clean_tombstones"

# Note, that neither delete_series nor clean_tombstones does not clean up list of labels
# so in autocompletion and tsdb-status you will still see
# all the deletes time series, even if they don't have any samples.
# Labels will be cleared automatically later, after a few hours.

# list all metrics that have specified labels
# source: https://stackoverflow.com/questions/70301131/how-to-get-all-metric-names-from-prometheus-server-filtered-by-a-particular-labe
curl -X GET -G "https://$prometheus_ingress/api/v1/label/__name__/values" --data-urlencode 'match[]={__name__=~".+", job="kubelet"}'

```

References:
- https://faun.pub/how-to-drop-and-delete-metrics-in-prometheus-7f5e6911fb33
- https://prometheus.io/docs/prometheus/latest/storage/#backfilling-for-recording-rules

# Show current config

```bash

kl -n prometheus exec sts/prometheus-main -it -- cat /etc/prometheus/config_out/prometheus.env.yaml

```

# Generate missing past metrics for a new recording rule

```bash

# enter the prometheus container
kl -n prometheus exec statefulsets/prometheus-main -it -- sh
# inside the container: find recording rule file and run promtool
ls -la /etc/prometheus/rules/prometheus-main-rulefiles-0/

# Be careful! Do not overlap time period with existing data!
# Be careful! Prometheus will consume large amount of memory during metric generation!
#             Use small rule files and/or small time intervals!
promtool tsdb create-blocks-from rules --start 2025-01-08T01:00:00+07:00 --end 2025-03-23T23:30:00+07:00 --output-dir=. --eval-interval=10s /etc/prometheus/rules/prometheus-main-rulefiles-0/prometheus-record-k8s-namespace-cpu-ceda2f82-7d83-4213-9ae8-f341d74f7e4a.yaml
# promtool works quickly, but if your date range is large, it will still take some time

```

# Delete all data

If you want to delete all data and start from scratch, you can either delete PVC completely,
or just delete `/prometheus` folder and restart prometheus.

```bash

# rm -rf will fail, it's OK, it just can't delete some of the special files
kl -n prometheus exec sts/prometheus-main -it -- rm -rf /prometheus
kl -n prometheus delete pod prometheus-main-0
kl -n prometheus get pod -o wide

```
