
# zeropod

References:
- https://github.com/ctrox/zeropod
- https://github.com/kubernetes/enhancements/issues/5091#issuecomment-2973784622

# Update

```bash

mkdir -p ./k8s-core/zeropod/env/
kl kustomize https://github.com/ctrox/zeropod/config/production?ref=main > ./k8s-core/zeropod/env/zeropod.gen.yaml
yq 'select(.kind == "CustomResourceDefinition")' ./k8s-core/zeropod/env/zeropod.gen.yaml > ./k8s-core/zeropod/crd.gen.yaml
yq 'select(.kind != "CustomResourceDefinition")' -i ./k8s-core/zeropod/env/zeropod.gen.yaml
cp ./k8s-core/zeropod/env/zeropod.gen.yaml ./k8s-core/zeropod/zeropod.gen.yaml

```

# Deploy

```bash

kl apply -f ./k8s-core/zeropod/crd.gen.yaml --server-side

kl create ns zeropod-system
kl label ns zeropod-system pod-security.kubernetes.io/enforce=privileged --overwrite

kl label node --all zeropod.ctrox.dev/node=true
kl apply -k ./k8s-core/zeropod/
kl -n zeropod-system get pod -o wide

```

# Cleanup

```bash

kl label node --all zeropod.ctrox.dev/node-
kl delete -f ./k8s-core/zeropod/zeropod.gen.yaml
kl delete ns zeropod-system
kl delete -f ./k8s-core/zeropod/crd.gen.yaml

```

# Test

```bash

kl create ns zeropod-test
kl label ns zeropod-test pod-security.kubernetes.io/enforce=baseline --overwrite

kl apply -f ./k8s-core/zeropod/test.yaml
kl -n zeropod-test get pod -o wide
kl -n zeropod-test describe pod -l app=nginx-zeropod
kl -n zeropod-test get events --sort-by='.lastTimestamp'

kl -n zeropod-test exec deployments/alpine -- apk add curl

while true; do
kl -n zeropod-test exec deployments/alpine -- curl -sS http://nginx-zeropod.zeropod-test
sleep 1
done

kl delete -f ./k8s-core/zeropod/test.yaml
kl delete ns zeropod-test

```
