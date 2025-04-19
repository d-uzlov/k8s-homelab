
# Open Kruise

References:
- https://openkruise.io/docs/next/installation/
- https://github.com/openkruise/kruise

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add openkruise https://openkruise.github.io/charts/
helm repo update openkruise
helm search repo openkruise/kruise --versions --devel | head
helm show values openkruise/kruise --version 1.8.0 > ./k8s-core/open-kruise/default-values.yaml
```

```bash

mkdir -p ./k8s-core/open-kruise/env/

kl kustomize https://github.com/openkruise/kruise/config/crd/?ref=v1.8.0 > ./k8s-core/open-kruise/crds.gen.yaml

helm template \
  open-kruise \
  openkruise/kruise \
  --version 1.8.0 \
  --values ./k8s-core/open-kruise/values.yaml \
  --namespace kruise-system \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' -e '\|creationTimestamp: null|d' \
  | sed '/# write a service account named kruise-helm-hook:/q' \
  | sed '/# write a service account named kruise-helm-hook:/{d; q}' \
  > ./k8s-core/open-kruise/env/open-kruise.gen.yaml

yq '
  select(
    .kind == "CustomResourceDefinition"
  )
' ./k8s-core/open-kruise/env/open-kruise.gen.yaml > ./k8s-core/open-kruise/crds.gen.yaml

yq '
  select(
    .kind != "CustomResourceDefinition"
  )
' -i ./k8s-core/open-kruise/env/open-kruise.gen.yaml

yq '
  select(
    .kind == "ClusterRole" or
    .kind == "Role" or
    .kind == "ClusterRoleBinding" or
    .kind == "RoleBinding"
  )
' ./k8s-core/open-kruise/env/open-kruise.gen.yaml > ./k8s-core/open-kruise/rbac.gen.yaml

yq '
  select(
    .kind != "ClusterRole" and
    .kind != "Role" and
    .kind != "ClusterRoleBinding" and
    .kind != "RoleBinding"
  )
' -i ./k8s-core/open-kruise/env/open-kruise.gen.yaml

yq '
  select(
    .kind == "ValidatingWebhookConfiguration" or
    .kind == "MutatingWebhookConfiguration"
  )
' ./k8s-core/open-kruise/env/open-kruise.gen.yaml > ./k8s-core/open-kruise/webhook.gen.yaml

yq '
  select(
    .kind != "ValidatingWebhookConfiguration" and
    .kind != "MutatingWebhookConfiguration"
  )
' ./k8s-core/open-kruise/env/open-kruise.gen.yaml > ./k8s-core/open-kruise/kruise.gen.yaml

```

# Deploy

```bash

kl apply -f ./k8s-core/open-kruise/crds.gen.yaml --server-side

kl create ns kruise-system
kl label ns kruise-system pod-security.kubernetes.io/enforce=privileged --overwrite
kl label ns kruise-system control-plane=openkruise --overwrite

kl apply -k ./k8s-core/open-kruise/
kl -n kruise-system get pod -o wide

```

# Cleanup

```bash
kl delete -k ./k8s-core/open-kruise/
kl delete ns kruise-system
kl delete -f ./k8s-core/open-kruise/crds.gen.yaml
```

# Test

```bash

kl apply -f ./k8s-core/open-kruise/test/cloneset-0-base.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset

# ====== Test various in-place updates ======

# changing annotations
# no restart expected
kl apply -f ./k8s-core/open-kruise/test/cloneset-1-annotation.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset
kl describe clone -l app=sample-cloneset | grep -e SuccessfulUpdatePodInPlace -e SuccessfulUpdatePodReCreate

# add resource requests/limits
# pod should restart because pod QoS changes
kl apply -f ./k8s-core/open-kruise/test/cloneset-2-resources-1.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset
kl describe clone -l app=sample-cloneset | grep -e SuccessfulUpdatePodInPlace -e SuccessfulUpdatePodReCreate

# change resource requests/limits
# no restart expected
kl apply -f ./k8s-core/open-kruise/test/cloneset-2-resources-2.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset
kl describe clone -l app=sample-cloneset | grep -e SuccessfulUpdatePodInPlace -e SuccessfulUpdatePodReCreate

# decrease memory limit
# restart because of k8s policy?
kl apply -f ./k8s-core/open-kruise/test/cloneset-2-resources-3.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset
kl describe clone -l app=sample-cloneset | grep -e SuccessfulUpdatePodInPlace -e SuccessfulUpdatePodReCreate

# change image
# no restart expected
kl apply -f ./k8s-core/open-kruise/test/cloneset-3-image.yaml
kl get pod -o wide -l app=sample-cloneset
kl describe pod -l app=sample-cloneset
kl describe clone -l app=sample-cloneset
kl describe clone -l app=sample-cloneset | grep -e SuccessfulUpdatePodInPlace -e SuccessfulUpdatePodReCreate

kl delete clone sample-cloneset

```
