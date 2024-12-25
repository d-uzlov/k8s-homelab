
# Setup

```bash
# remove min interval settings from all panels
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
