
# Pod name webhook

References:
- https://github.com/d-uzlov/pod-name-wh

# Deploy

```bash

kl create ns pod-name-wh
kl label ns pod-name-wh pod-security.kubernetes.io/enforce=privileged

kl apply -k ./k8s-core/pod-name-webhook/
kl -n pod-name-wh get pod -o wide

```

# Cleanup

```bash
kl delete -k ./k8s-core/pod-name-wh/
kl delete ns pod-name-wh
```

# Usage example

See kyverno policies [example](../kyverno/common-policies/daemonset-name-label.yaml)
