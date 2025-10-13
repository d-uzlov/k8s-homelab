
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
helm search repo kyverno/kyverno --versions --devel | head
helm show values kyverno/kyverno --version 3.5.2 > ./k8s-core/kyverno/default-values.yaml
```

```bash

helm template --no-hooks \
  kyverno \
  kyverno/kyverno \
  --version 3.5.2 \
  --values ./k8s-core/kyverno/values.yaml \
  --namespace kyverno \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' \
  | sed 's/kyverno-admission-controller/kyverno-admission/' \
  > ./k8s-core/kyverno/deployment.gen.yaml

```

# Deploy

```bash

kl apply -k ./k8s-core/kyverno/crds/ --server-side

kl create ns kyverno
kl label ns kyverno pod-security.kubernetes.io/enforce=baseline
kl label ns kyverno kubernetes.io/namespace-type=system-critical --overwrite

kl apply -k ./k8s-core/kyverno/
kl -n kyverno get pod -o wide

kl -n kyverno logs deployments/kyverno-admission

kl apply -k ./k8s-core/kyverno/common-policies/
kl get clusterpolicy

```

# Cleanup

```bash
kl delete -k ./k8s-core/kyverno/common-policies/
kl delete -k ./k8s-core/kyverno/
kl delete ns kyverno
kl delete validatingwebhookconfiguration -l webhook.kyverno.io/managed-by=kyverno
kl delete mutatingwebhookconfiguration -l webhook.kyverno.io/managed-by=kyverno
kl delete -k ./k8s-core/kyverno/crds/
```
