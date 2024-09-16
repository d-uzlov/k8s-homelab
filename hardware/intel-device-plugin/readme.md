
# Intel k8s device plugin

References:
- https://intel.github.io/intel-device-plugins-for-kubernetes/cmd/gpu_plugin/README.html
- https://github.com/intel/intel-device-plugins-for-kubernetes
- https://github.com/intel/helm-charts

# Prerequisites

References:
- [node-feature-discovery](../node-feature-discovery/readme.md)

# Update

```bash
helm repo add intel https://intel.github.io/helm-charts
helm repo update intel
helm search repo intel/intel-device-plugins-gpu --versions --devel | head
helm show values intel/intel-device-plugins-gpu --version 0.30.0 > ./hardware/intel-device-plugin/default-values.yaml
helm search repo intel/intel-device-plugins-gpu --versions --devel | head
helm show values intel/intel-device-plugins-operator --version 0.30.0 > ./hardware/intel-device-plugin/operator/default-values.yaml
```

```bash
kl kustomize https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/operator/crd?ref=v0.30.0 \
  > ./hardware/intel-device-plugin/operator/crds.gen.yaml

helm template \
  intel-operator \
  intel/intel-device-plugins-operator \
  --version 0.30.0 \
  --namespace hw-intel \
  --values ./hardware/intel-device-plugin/operator/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  | sed -e 's/inteldeviceplugins-controller-manager-metrics-service/operator-metrics/g' \
  | sed -e 's/inteldeviceplugins-controller-manager/operator/g' \
  | sed -e 's/inteldeviceplugins-validating-webhook-configuration/intel-operator-val/g' \
  | sed -e 's/inteldeviceplugins-mutating-webhook-configuration/intel-operator-mut/g' \
  | sed -e 's/inteldeviceplugins-serving-cert/operator/g' \
  | sed -e 's/inteldeviceplugins-webhook-service/operator-webhook/g' \
  | sed -e 's/inteldeviceplugins-gpu-manager-rolebinding/intel-gpu-manager/g' \
  | sed -e 's/inteldeviceplugins-gpu-manager-role/intel-gpu-manager/g' \
  | sed -e 's/inteldeviceplugins-manager-rolebinding/intel-manager/g' \
  | sed -e 's/inteldeviceplugins-manager-role/intel-manager/g' \
  | sed -e 's/inteldeviceplugins-proxy-rolebinding/intel-proxy/g' \
  | sed -e 's/inteldeviceplugins-proxy-role/intel-proxy/g' \
  | sed -e 's/inteldeviceplugins-leader-election-role/operator-leader-election/g' \
  | sed -e 's/inteldeviceplugins-leader-election-rolebinding/operator-leader-election/g' \
  | sed -e 's/inteldeviceplugins-selfsigned-issuer/selfsigned/g' \
  | sed -e 's/inteldeviceplugins-metrics-reader/intel-operator-metrics-reader/g' \
  > ./hardware/intel-device-plugin/operator/intel-operator.gen.yaml

helm template \
  intel-gpu-plugin \
  intel/intel-device-plugins-gpu \
  --version 0.30.0 \
  --namespace hw-intel \
  --values ./hardware/intel-device-plugin/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./hardware/intel-device-plugin/intel-gpu-plugin.gen.yaml
```

# Deploy

```bash
kl apply -f ./hardware/intel-device-plugin/operator/crds.gen.yaml --server-side

kl create ns hw-intel
kl label ns hw-intel pod-security.kubernetes.io/enforce=privileged

# kl -n hw-intel apply -f ./network/network-policies/deny-ingress.yaml
# kl -n hw-intel apply -f ./network/network-policies/allow-same-namespace.yaml

kl apply -f ./hardware/intel-device-plugin/operator/intel-operator.gen.yaml
kl -n hw-intel apply -f ./hardware/intel-device-plugin/intel-gpu-plugin.gen.yaml
kl -n hw-intel get pod -o wide
```

# Cleanup

```bash
kl delete -f ./hardware/intel-device-plugin/intel-gpu-plugin.gen.yaml
kl delete -f ./hardware/intel-device-plugin/operator/intel-operator.gen.yaml
kl delete -f ./hardware/intel-device-plugin/operator/crds.gen.yaml
kl delete ns hw-intel
```

# Test that pods can access GPU

```bash
kl create ns hw-intel-test
kl -n hw-intel-test apply -f ./hardware/intel-device-plugin/test.yaml
kl -n hw-intel-test get pod -o wide
kl -n hw-intel-test logs jobs/intelgpu-demo-job | less

kl delete ns hw-intel-test
```

References:
- https://github.com/intel/intel-device-plugins-for-kubernetes/blob/main/cmd/gpu_plugin/README.md#testing-and-demos
- https://github.com/intel/intel-device-plugins-for-kubernetes/blob/bcf8f016107de64539343a9996f17e2bd42833c9/demo/intelgpu-job.yaml

# GPU load monitoring

```bash
sudo apt install -y intel-gpu-tools
intel_gpu_top
```
