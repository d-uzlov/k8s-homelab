
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
helm show values cnpg/cloudnative-pg --version 0.23.2 > ./storage/postgres-cnpg/default-values.yaml
```

```bash

kubectl kustomize "github.com/cloudnative-pg/cloudnative-pg/config/crd?ref=v1.25.1" > ./storage/postgres-cnpg/crd.yaml

helm template \
  cnpg \
  cnpg/cloudnative-pg \
  --version 0.23.2 \
  --namespace pgo-cnpg \
  --values ./storage/postgres-cnpg/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/postgres-cnpg/cnpg.gen.yaml

```

# Deploy

```bash

kl apply -f ./storage/postgres-cnpg/crd.yaml --server-side --force-conflicts

kl create ns pgo-cnpg
kl label ns pgo-cnpg pod-security.kubernetes.io/enforce=baseline

kl apply -f storage/postgres-cnpg/cnpg.gen.yaml
kl -n pgo-cnpg get pod -o wide

# sometimes postgres operator is stuck
kl -n pgo-cnpg logs deployments/cnpg > ./cnpg.log

```

# Cleanup

```bash

kl delete -f storage/postgres-cnpg/cnpg.gen.yaml
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

# Test

References:
- https://cloudnative-pg.io/documentation/1.25/samples/

```bash

cat << EOF > ./storage/postgres-cnpg/test/env/postgres-sc.env
postgres_storage_class=nvmeof
EOF

kl create ns pgo-cnpg-test

kl apply -k ./storage/postgres-cnpg/test/

kl -n pgo-cnpg-test get cluster
kl -n pgo-cnpg-test describe cluster postgres
kl -n pgo-cnpg-test get pvc
kl -n pgo-cnpg-test get pods -o wide -L role -L cnpg.io/jobRole
kl -n pgo-cnpg-test get svc
kl -n pgo-cnpg-test get secrets
kl cnpg -n pgo-cnpg-test status postgres

# list users
kl -n pgo-cnpg-test exec pods/postgres-1 -- psql template1 --command '\du'
# list databases
kl -n pgo-cnpg-test exec pods/postgres-1 -- psql --list

# "cnpg psql" can automatically finds the master instance
kl cnpg -n pgo-cnpg-test psql postgres -- --command '\du'
kl cnpg -n pgo-cnpg-test psql postgres -- --list

# warning: PVCs will be deleted automatically
kl delete -k ./storage/postgres-cnpg/test/
kl delete ns pgo-cnpg-test

```
