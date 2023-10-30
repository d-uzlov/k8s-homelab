
# Intel k8s device plugin

References:
- https://github.com/NVIDIA/k8s-device-plugin#quick-start
- https://github.com/NVIDIA/gpu-operator/issues/114

Config in this folder enables GPU sharing with up to 8 clients per GPU.

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
  --namespace hw-nvidia \
  --values ./hardware/nvidia-device-plugin/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./hardware/nvidia-device-plugin/nvdp.gen.yaml
```

# Deploy

```bash
kl create ns hw-nvidia
kl apply -k ./hardware/nvidia-device-plugin/
kl -n hw-nvidia get pod -o wide

# check that node now has nvidia gpu capacity
kl describe node | grep nvidia.com/gpu: -B 7
# check that gfd found your GPU and labeled node (it can take some time to be populated)
kl describe node | grep -e nvidia.com/cuda -e nvidia.com/gpu\\. -e nvidia.com/mig
```

# Cleanup

```bash
kl delete -f ./hardware/nvidia-device-plugin/nvdp.gen.yaml
kl delete ns hw-nvidia
```

# Test that pods can access GPU

```bash
kl apply -f ./hardware/nvidia-device-plugin/test.yaml
kl get pod
kl logs pods/gpu-pod

kl delete -f ./hardware/nvidia-device-plugin/test.yaml
```

# Enable container to access additional GPU functions

You can use `NVIDIA_DRIVER_CAPABILITIES` env
with a list of following comma-separated values:

- `compute`: required for CUDA and OpenCL applications.
- `compat32`: required for running 32-bit applications.
- `graphics`: required for running OpenGL and Vulkan applications.
- `utility`: required for using `nvidia-smi` and NVML.
- `video`: required for using the Video Codec SDK.
- `display`: required for leveraging X11 display.
- `all`: all of the above

Default value is `utility,compute`.

References:
- https://github.com/NVIDIA/nvidia-container-runtime
