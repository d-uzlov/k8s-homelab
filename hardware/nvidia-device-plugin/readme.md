
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
  --namespace hw-ndivia \
  --values ./hardware/nvidia-device-plugin/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./hardware/nvidia-device-plugin/nvdp.gen.yaml
```

# Deploy

```bash
kl create ns hw-ndivia
kl apply -f ./hardware/nvidia-device-plugin/nvdp.gen.yaml
kl -n hw-ndivia get pod

# check that node now has nvidia gpu capacity
kl describe node | grep nvidia.com/gpu: -B 7
# check that gfd found your GPU and labeled node
kl describe node | grep nvidia.com/gpu.product
```

# Cleanup

```bash
kl delete -f ./hardware/nvidia-device-plugin/nvdp.gen.yaml
kl delete ns hw-ndivia
```

# Test that pods can access GPU

```bash
kl apply -f ./hardware/nvidia-device-plugin/test.yaml
kl get pod
kl logs pods/gpu-pod

kl delete -f ./hardware/nvidia-device-plugin/test.yaml
```
