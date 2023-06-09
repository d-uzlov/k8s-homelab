
# Replicator

https://github.com/mittwald/kubernetes-replicator#push-based-replication

This app can automatically copy secrets and config maps between namespaces based on annotations.

# Generate deployment

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
kl apply -f ./ingress/replicator/test.yaml

kl create ns replicator-demo

kl -n replicator-demo get secret

kl label ns --overwrite replicator-demo test-label=some-value

kl -n replicator-demo get secret
```

# How to use

Add annotation to secret or config map:
```yaml
replicator.v1.mittwald.de/replicate-to-matching: some-unique-name=value
```

Enable push for namespace:
```bash
kl label ns --overwrite namespace-name some-unique-name=value
```
