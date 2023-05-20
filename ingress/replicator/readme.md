
https://github.com/mittwald/kubernetes-replicator#push-based-replication

# Install

```bash
helm repo add mittwald https://helm.mittwald.de

helm repo update

helm template kubernetes-replicator \
    --version 2.8.0 \
    --values ./ingress/replicator/helm-values.yaml \
    mittwald/kubernetes-replicator \
    > ./ingress/replicator/replicator.yaml

kl apply -k ./ingress/replicator/
```

# How to use

Push from secret:
```yaml
    replicator.v1.mittwald.de/replicate-to-matching: >
      copy-wild.local/domainname=true
```

Enable push for namespace:
```bash
kl label ns demo copy-wild.local/domainname=true
```
