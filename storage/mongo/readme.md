
# MongoDB Operator

This application can automatically create and change mongodb clusters in k8s.

References:
- https://www.mongodb.com/try/download/community-kubernetes-operator
- https://github.com/mongodb/mongodb-kubernetes-operator/

# Generate config

You only need to do this when updating the app.

```bash
helm repo add mongodb https://mongodb.github.io/helm-charts
helm repo update mongodb
helm search repo mongodb/community-operator --versions --devel | head
helm show values mongodb/community-operator --version 0.10.0 > ./storage/mongo/default-values.yaml
```

```bash

helm template \
  mongo-operator-crds \
  mongodb/community-operator-crds \
  --version 0.10.0 \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/mongo/mongo-crds.gen.yaml

helm template \
  mongo-operator \
  mongodb/community-operator \
  --version 0.10.0 \
  --namespace mongo-operator \
  --values ./storage/mongo/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/mongo/mongo.gen.yaml

```

# Deploy

```bash
kl apply -f ./storage/mongo/mongo-crds.gen.yaml --server-side

# set the storage class for mongo PVCs
mkdir -p ./storage/mongo/pvc-config/env/
 cat << EOF > ./storage/mongo/test-cluster/pvc/env/pvc.env
data_class=block
logs_class=block
EOF

kl create ns mongo-operator
kl apply -f ./storage/mongo/mongo.gen.yaml
kl -n mongo-operator get pod -o wide

kl -n mongo-operator logs deployments/mongo-operator
```

# Cleanup

```bash
kl delete -f ./storage/mongo/mongo.gen.yaml
kl delete ns mongo-operator
kl delete -f ./storage/mongo/mongo-crds.gen.yaml
```

# Test

```bash
mkdir -p ./storage/mongo/test-cluster/env/
 cat << EOF > ./storage/mongo/test-cluster/env/password.env
password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF

kl create ns mongo-test
kl apply -k ./storage/mongo/test-cluster/
kl -n mongo-test get mongodbcommunity

kl -n mongo-test get statefulsets.apps mongo
kl -n mongo-test describe statefulsets.apps mongo
kl -n mongo-test get pvc
kl -n mongo-test get pod
kl -n mongo-test describe pod mongo-0

# at this point you can connect to database,
# check out the "Check DB state" paragraph

kl delete -k ./storage/mongo/test-cluster/
kl delete ns mongo-test
```

# Check DB state

```bash
connection=$(kl -n mongo-test get secrets mongo-admin-admin -o go-template --template '{{ index .data "connectionString.standardSrv" }}' | base64 -d)
kl -n mongo-test exec sts/mongo -it -- mongosh "$connection"

kl expose service -n mongo-test mongo-svc --type LoadBalancer --name mongo-external
lbIp=$(kl -n mongo-test get svc mongo-external -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
mongosh "mongodb://my-user@$lbIp/admin?ssl=true"
```

# Deploy database

Copy the [test-cluster](./test-cluster/) folder and change the namespace.

If needed, add more users.

Create a new password for each user.
