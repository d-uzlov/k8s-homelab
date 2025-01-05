
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

References:
- https://stackoverflow.com/questions/68409322/prometheus-cannot-scrape-kubernetes-metrics

# Manual metric checking

```bash
bearer=$(kl -n kps exec sts/prometheus-kps -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
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

# coredns metrics
# these metrics are not monitored here
kl exec deployments/alpine -- curl -sS http://kube-dns.kube-system:9153/metrics

# apiserver metrics
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kubernetes.default:443/metrics
# kube-controller-manager metrics
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kps-kube-controller-manager.kube-system:10257/metrics
# kube-scheduler metrics
kl exec deployments/alpine -- curl -sS --insecure -H "Authorization: Bearer $bearer" https://kps-kube-scheduler.kube-system:10259/metrics

```
