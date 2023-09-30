
# Intel k8s device plugin

References:
- https://github.com/NVIDIA/k8s-device-plugin#quick-start

# Generate config

You only need to do this when updating the app.

```bash
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update nvdp
helm search repo nvdp/nvidia-device-plugin --versions --devel | head
helm show values nvdp/nvidia-device-plugin > ./hardware/nvidia-device-plugin/default-values.yaml
```

```bash
helm template \
  nvdp \
  nvdp/nvidia-device-plugin \
  --version 0.14.1 \
  --namespace hardware \
  --values ./hardware/nvidia-device-plugin/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./hardware/nvidia-device-plugin/nvdp.gen.yaml
```

# Deploy

```bash
kl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd/overlays/node-feature-rules?ref=v0.28.0

kl create ns hardware
kl apply -f ./hardware/nvidia-device-plugin/nvdp.gen.yaml
kl -n nfd get pod
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
