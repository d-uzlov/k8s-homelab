
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

# pgbouncer

Each connection to a postgres server creates a new postgres process,
which increases RSS memory usage.
Even is connection is idle, it will still use memory.

Postgres doesn't have a way to limit number of connections.
But you can deploy pgbouncer, which is essentially a postgres proxy.
It can keep a pool of connections.
If postgres clients open a lot of connections, but only use a handful at a time,
you can save a lot of memory by using pgbouncer.

Unfortunately, I found an issue combining CNPG and pgbouncer:
CNPG want to deploy pgbouncer as a separate deployment via `Pooler` resource, which defeats its purpose for memory saving.
If you have `N` pgbouncer replicas, and want to keep `M` connections,
then you will instead end up with `N × M` connections.
Even 2 replicas will most likely increase your postgres memory usage.

But if you only deploy a single instance of pgbouncer,
then you effectively give up high availability.

A solution would be to deploy pgbouncer as a sidecar container for postgres.
Unfortunately, CNPG doesn't support this mode:
- https://github.com/cloudnative-pg/cloudnative-pg/issues/5751

Also, CNPG doesn't want to support sidecar containers.
Well, it technically supports them via a JSON patch using annotations,
but they surely treat is as abuse.

And configuring pgbouncer manually would require you
to also manually configure all authentication, which strips part of CNPG convenience.

A proper solution, which has a possibility to be implemented, is to use `CNPG-I`™,
or, in other words, write a plugin for CNPG that will inject pgbouncer as sidecar.
Unfortunately, no one cas created such a plugin yet.

Also, apparently Yandex Odyssey is a better implementation of the same idea, but CNPG doesn't support it either:
- https://github.com/cloudnative-pg/cloudnative-pg/issues/718
