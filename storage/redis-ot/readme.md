
# Redis Operator from ot-container-kit

References:
- https://github.com/OT-CONTAINER-KIT/redis-operator
- https://ot-redis-operator.netlify.app/docs/installation/installation/

# Generate config

You only need to do this when updating the app.

```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
helm repo update ot-helm
helm search repo ot-helm/redis-operator --versions --devel | head
helm show values ot-helm/redis-operator --version 0.18.5 > ./storage/redis-ot/default-values.yaml
```

```bash

(
  cd ./storage/redis-ot/crds/
  rm redis.redis.opstreelabs.in*
  wget https://github.com/OT-CONTAINER-KIT/redis-operator/raw/refs/tags/v0.18.1/config/crd/bases/redis.redis.opstreelabs.in_redis.yaml
  wget https://github.com/OT-CONTAINER-KIT/redis-operator/raw/refs/tags/v0.18.1/config/crd/bases/redis.redis.opstreelabs.in_redisclusters.yaml
  wget https://github.com/OT-CONTAINER-KIT/redis-operator/raw/refs/tags/v0.18.1/config/crd/bases/redis.redis.opstreelabs.in_redisreplications.yaml
  wget https://github.com/OT-CONTAINER-KIT/redis-operator/raw/refs/tags/v0.18.1/config/crd/bases/redis.redis.opstreelabs.in_redissentinels.yaml
)

helm template \
  redis-operator \
  ot-helm/redis-operator \
  --version 0.18.5 \
  --namespace redis-operator \
  --values ./storage/redis-ot/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./storage/redis-ot/redis.gen.yaml

```

# Deploy

```bash
kl apply -k ./storage/redis-ot/crds/ --server-side --force-conflicts
kl apply -f ./storage/redis-ot/roles/

kl create ns redis-operator
kl label ns redis-operator pod-security.kubernetes.io/enforce=baseline

kl apply -k ./storage/redis-ot/
kl -n redis-operator get pod -o wide

```

# Cleanup

```bash
kl delete -k ./storage/redis-ot/
kl delete ns redis-operator
kl delete -k ./storage/redis-ot/crds/
```

# Test

This test assumes that you have `nvmeof` storage class in your cluster.
Change `spec.storage.volumeClaimTemplate.spec.storageClassName` if you want to use something different.

TODO this doesn't work because redis password secret is missing

```bash

mkdir -p ./storage/redis-ot/test/env/
 cat << EOF > ./storage/redis-ot/test/env/redis-password.env
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
 cat << EOF > ./storage/redis-ot/test/env/pvc.env
storage_class=nvmeof
EOF

kl create ns redis-test
kl label ns redis-test pod-security.kubernetes.io/enforce=baseline

kl -n redis-test apply -k ./storage/redis-ot/test/
kl -n redis-test get redis
kl -n redis-test describe redis

kl -n redis-test get pods -o wide
kl -n redis-test get pvc
kl -n redis-test get svc

kl delete -f ./storage/redis-ot/test/test-redis.yaml
kl delete ns redis-test
```
