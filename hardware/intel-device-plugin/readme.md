
# Intel k8s device plugin

References:
- https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html
- https://github.com/intel/intel-device-plugins-for-kubernetes
- https://github.com/intel/helm-charts

# Deploy

```bash
kl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd/overlays/node-feature-rules?ref=v0.28.0

kl create ns hardware
kl apply -n hardware -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/monitoring_shared-dev_nfd/?ref=v0.28.0
kl -n hardware get pod
```

# Test that pods can access GPU

```bash
kl apply -f ./hardware/intel-device-plugin/test.yaml
kl get pod
kl logs jobs/intelgpu-demo-job | less

kl delete -f ./hardware/intel-device-plugin/test.yaml
```

References:
- https://github.com/intel/intel-device-plugins-for-kubernetes/blob/main/cmd/gpu_plugin/README.md#testing-and-demos
- https://github.com/intel/intel-device-plugins-for-kubernetes/blob/bcf8f016107de64539343a9996f17e2bd42833c9/demo/intelgpu-job.yaml

# GPU load monitoring

```bash
sudo apt install -y intel-gpu-tools
intel_gpu_top
```
