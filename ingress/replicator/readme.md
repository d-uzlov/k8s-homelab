
# Replicator

This app can automatically copy secrets and config maps between namespaces based on annotations.

References:
- https://github.com/mittwald/kubernetes-replicator#push-based-replication

# Generate deployment

Required for major config changes or updates.

You don't need to do it if you are just deploying it.

```bash
helm repo add mittwald https://helm.mittwald.de
helm repo update
helm template kubernetes-replicator \
    mittwald/kubernetes-replicator \
    --version 2.8.0 \
    --values ./ingress/replicator/helm-values.yaml \
    --namespace replicator \
    > ./ingress/replicator/replicator.gen.yaml
```

# Deploy

```bash
kl create ns replicator
kl apply -k ./ingress/replicator/
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
