
# Postgres Operator

This application can automatically create and change postgres clusters in k8s.

References:
- https://github.com/cloudnative-pg/cloudnative-pg
- https://github.com/cloudnative-pg/charts
- https://cloudnative-pg.io/documentation/1.25/installation_upgrade/

# Generate config

You only need to do this when updating the app.

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update cnpg
helm search repo cnpg/cloudnative-pg --versions --devel | head
helm show values cnpg/cloudnative-pg --version 0.26.0 > ./storage/postgres-cnpg/default-values.yaml
```

```bash

kubectl kustomize "github.com/cloudnative-pg/cloudnative-pg/config/crd?ref=v1.27.0" > ./storage/postgres-cnpg/crd.yaml

helm template \
  cnpg \
  cnpg/cloudnative-pg \
  --version 0.26.0 \
  --namespace pgo-cnpg \
  --values ./storage/postgres-cnpg/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/postgres-cnpg/cnpg.gen.yaml

```

# Deploy

```bash

clusterName=
 cat << EOF > ./storage/postgres-cnpg/env/patch-location-tag.yaml
- op: add
  path: /spec/podMetricsEndpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

kl apply -f ./storage/postgres-cnpg/crd.yaml --server-side --force-conflicts

kl create ns pgo-cnpg
kl label ns pgo-cnpg pod-security.kubernetes.io/enforce=baseline

kl apply -k ./storage/postgres-cnpg/
kl -n pgo-cnpg get pod -o wide

kl -n pgo-cnpg logs deployments/cnpg > ./cnpg.log

kl -n pgo-cnpg describe pmon all-cnpg-clusters

# metrics from cnpg controller are useless
# curl 10.3.132.195:9187/metrics > ./pg.prom

```

# Cleanup

```bash
kl delete -k ./storage/postgres-cnpg/
kl delete ns pgo-cnpg
kl delete -f ./storage/postgres-cnpg/crd.yaml
```

# Kubectl plugin

Prerequisites:
- [Krew](../../docs/k8s/krew.md#install)

```bash

kl krew install cnpg
kl krew update
kl krew upgrade cnpg

# enable autocompletion
# script must be accessible by running "exec kubectl_complete-cnpg"
# https://cloudnative-pg.io/documentation/1.25/kubectl-plugin/#configuring-auto-completion
 sudo tee /usr/local/bin/kubectl_complete-cnpg << "EOF"
#!/usr/bin/env sh

# Call the __complete command passing it all arguments
kubectl cnpg __complete "$@"
EOF

sudo chmod +x /usr/local/bin/kubectl_complete-cnpg

```
