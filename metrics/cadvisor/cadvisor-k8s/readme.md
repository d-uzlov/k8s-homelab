
# Local config setup

```bash

mkdir -p ./metrics/cadvisor/cadvisor-k8s/env/

# example:
# location_tag=vps/k8s/clusterName
location_tag=

 cat << EOF > ./metrics/cadvisor/cadvisor-k8s/env/patch-location-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: location
    replacement: $clusterName
    action: replace
EOF

```

# Deploy

```bash

kl create ns metrics-cadvisor
# cadvisor needs access to various host folders
kl label ns metrics-cadvisor pod-security.kubernetes.io/enforce=privileged

kl apply -k ./metrics/cadvisor/cadvisor-k8s/
kl -n metrics-cadvisor get pod

# add optional annotations to nodes
kl annotate node $node_name metric-identifier=$global_unique_node_address

```

# Cleanup

```bash
kl delete -k ./metrics/cadvisor/cadvisor-k8s/
kl delete ns metrics-cadvisor
```

# Manual metric checking

```bash

kl exec deployments/alpine -- curl -sS http://cadvisor.metrics-cadvisor:8999/metrics > ./cadvisor.prom

```
