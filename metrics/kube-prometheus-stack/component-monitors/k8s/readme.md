
# Setup

```bash
# remove min interval settings from all panels to force them to use the default data source min interval
# be careful: some panels need bigger interval to work properly
sed -i '/\"interval\":/d' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json
# remove id to avoid collisions
sed -i 's/^  \"id\": .*,/  \"id\": null,/' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json
# set dashboard refresh interval to auto
sed -i 's/^  \"refresh\": \".*s\",/  \"refresh\": \"auto\",/' ./metrics/kube-prometheus-stack/component-monitors/k8s/*.json

kl apply -k ./metrics/kube-prometheus-stack/component-monitors/k8s/
```

# Cleanup

```bash
kl delete -k ./metrics/kube-prometheus-stack/component-monitors/k8s/
```

# Issues

- https://github.com/google/cadvisor/issues/3588

# TODO

Why do many storage-related queries had `device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"` selector in default dashboards?

`container_network_receive_packets_total`: very high cardinality

`*volume*` metrics are duplicated between kubelet and kube-state-metrics?

Use `kube_pod_spec_volumes_persistentvolumeclaims_info` to link PVCs to compute resources?

Add node name into pod detailed info.

Add "currently running" status into pod tables.

Add throttling info into pod tables.
