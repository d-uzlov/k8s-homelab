
# Replicator

This app can automatically copy secrets and config maps between namespaces based on annotations.

References:
- https://github.com/mittwald/kubernetes-replicator#push-based-replication

# Generate config

You only need to do this when updating the app.

```bash
helm repo add mittwald https://helm.mittwald.de
helm repo update mittwald
helm search repo mittwald/kubernetes-replicator --versions --devel | head
helm show values mittwald/kubernetes-replicator --version 2.9.2 > ./ingress/replicator/default-values.yaml
```

```bash
helm template \
    kubernetes-replicator \
    mittwald/kubernetes-replicator \
    --version 2.9.2 \
    --values ./ingress/replicator/helm-values.yaml \
    --namespace replicator \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' \
    > ./ingress/replicator/replicator.gen.yaml
```

# Deploy

```bash
kl create ns replicator
kl label ns replicator pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/replicator/
kl -n replicator get pod -o wide
```

# Test that it works

```bash
# create a test secret
kl apply -f ./ingress/replicator/test.yaml

kl create ns replicator-demo

# by default secrets are not replicated
kl -n replicator-demo get secret

# enable replication for this namespace
# label value is taken from the secret description
kl label ns --overwrite replicator-demo test-label=some-value

# check that now the secret is replicated
kl -n replicator-demo get secret

kl delete ns replicator-demo
```

# How to use

Add annotation to secret or config map,
to allow replicator to copy it:

```yaml
replicator.v1.mittwald.de/replicate-to-matching: some-unique-name=value
```

Enable push for a selected namespace by setting the same label:

```bash
kl label ns --overwrite namespace-name some-unique-name=value
```
