
# Kyverno

Kyverno is a "policy engine" for k8s.
Which basically means it can validate and modify k8s resources
based on set of rules defined by cluster admin.

References:
- https://kyverno.io/docs/
- https://github.com/kyverno/kyverno

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update kyverno
helm search repo kyverno
helm search repo kyverno/kyverno --versions --devel | head
helm show values kyverno/kyverno --version 3.1.4 > ./metrics/kyverno/default-values.yaml
```

```bash

helm template \
  kyverno \
  kyverno/kyverno \
  --version 3.1.4 \
  --values ./metrics/kyverno/values.yaml \
  --namespace kyverno \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' \
  > ./metrics/kyverno/deployment.gen.yaml

```

# Deploy

```bash

kl apply -k ./metrics/kyverno/crds/ --server-side

kl create ns kyverno
kl label ns kyverno pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/kyverno/
kl -n kyverno get pod -o wide

kl apply -k ./metrics/kyverno/common-policies/
kl get clusterpolicy

```

# Cleanup

```bash
kl delete -k ./metrics/kyverno/
kl delete ns kyverno
kl delete validatingwebhookconfiguration -l webhook.kyverno.io/managed-by=kyverno
kl delete mutatingwebhookconfiguration -l webhook.kyverno.io/managed-by=kyverno
kl delete -k ./metrics/kyverno/crds/
```
