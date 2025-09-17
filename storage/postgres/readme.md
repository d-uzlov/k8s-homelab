
# Postgres Operator

This application can automatically create and change postgres clusters in k8s.

References:
- https://github.com/zalando/postgres-operator
- https://postgres-operator.readthedocs.io/en/latest/quickstart/

# Generate config

You only need to do this when updating the app.

```bash
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo update postgres-operator-charts
helm search repo postgres-operator-charts/postgres-operator --versions --devel | head
helm show values postgres-operator-charts/postgres-operator --version 1.14.0 > ./storage/postgres/default-values.yaml
```

```bash

helm template \
  postgres-operator \
  postgres-operator-charts/postgres-operator \
  --version 1.14.0 \
  --namespace postgres-operator \
  --values ./storage/postgres/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/postgres/postgres.gen.yaml

```

# Deploy

```bash

kl apply -k ./storage/postgres/crd/ --server-side --force-conflicts
kl apply -f ./storage/postgres/roles/

kl create ns postgres-operator
kl label ns postgres-operator pod-security.kubernetes.io/enforce=baseline

kl apply -k ./storage/postgres/
kl -n postgres-operator get pod -o wide

# sometimes postgres operator is stuck
kl -n postgres-operator rollout restart deployment postgres-operator
kl -n postgres-operator logs deployments/postgres-operator --follow > ./postgres-operator.log

```

# Cleanup

```bash

kl delete -k ./storage/postgres/
kl delete -f ./storage/postgres/roles/
kl delete ns postgres-operator
kl delete -k ./storage/postgres/crd/

```

# Get current config from the cluster:

```bash

kl -n postgres-operator get operatorconfiguration postgres-operator -o yaml > ./storage/postgres/current-config.yaml

```

# Test

This test assumes that you have `block` storage class in your cluster.
Change `spec.volume.storageClass` if you want to use something different.

```bash

kl create ns postgres-test

kl apply -k ./storage/postgres/test/

kl -n postgres-test get postgresql
kl -n postgres-test describe postgresql
kl -n postgres-test get pvc
kl -n postgres-test get pods -o wide -L spilo-role
kl -n postgres-test get svc

# list users
kl -n postgres-test exec pods/postgres-0 -- psql template1 -c '\du'
# list databases
kl -n postgres-test exec pods/postgres-0 -- psql --list

kl delete -k ./storage/postgres/test/
kl delete ns postgres-test

```

# Possible deadlock

Don't forget to set:

```yaml
configuration:
  kubernetes:
    pod_management_policy: parallel
```

`parallel` flag fixes the following issue:

- you create postgres with 2 replicas
- you delete postgres-0
- postgres-1 becomes the leader
- you reboot the cluster (or do anything else for both pods to be restarted)
- k8s creates postgres-0 and waits for it to become Ready
- postgres-0 waits for the postgres-1
- postgres-0 is waiting forever

The issue is also described here:

- https://github.com/zalando/postgres-operator/issues/1978
- https://github.com/zalando/postgres-operator/issues/2003

# Check DB state

```bash
# list databases
psql --list
# list users
psql template1 -c '\du'

psql -c 'create database test;'

# change password for username
psql -c "ALTER USER username WITH PASSWORD 'qwerty';"
```

# Database not created

Check that database name is correct.

For example, postgres doesn't allow `-` in database names.

This operator doesn't seem to have any indication of such errors.
