
# cgroup-burst

References:
- https://github.com/d-uzlov/k8s-cgroup-burst-controller

# Update

```bash

wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/raw/refs/heads/main/deployment/daemonset.yaml -O k8s-core/cgroup-burst/daemonset.yaml
wget https://github.com/d-uzlov/k8s-cgroup-burst-controller/raw/refs/heads/main/deployment/rbac.yaml -O k8s-core/cgroup-burst/rbac.yaml

```

# Requirements

You need to run a modified Linux kernel for this to work.
See upstream repo for details.

# Deploy

```bash

kl create ns cgroup-burst
# cgroup-burst needs access to hostPath volumes to access containerd directly
kl label ns cgroup-burst pod-security.kubernetes.io/enforce=privileged

# add label to all nodes that have compatible kernel
node=
kl label node $node cgroup.meoe.io/node=enable

kl apply -k ./k8s-core/cgroup-burst/
kl -n cgroup-burst get pod -o wide

```

# Cleanup

```bash
kl delete -k ./k8s-core/cgroup-burst/
kl delete ns cgroup-burst
```

# Usage example

Test on a single pod:

```bash

kl label pod $pod_name cgroup.meoe.io/burst=enable
kl annotate pod $pod_name cgroup.meoe.io/burst=$container_name=$burst_time
# check pod events for errors and info
kl describe pod $pod_name

```

You can add the annotation to pod template of your deployment:

```yaml
metadata:
  labels:
    cgroup.meoe.io/burst: enable
  annotations:
    cgroup.meoe.io/burst: nginx=10ms
```

# Manual metric checking

```bash
kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://cgroup-burst.cgroup-burst:2112/metrics > ./cgroup-burst-own-metrics.log
kl exec deployments/alpine -- curl -sS http://cgroup-burst.cgroup-burst:2112/container_metrics > ./cgroup-burst-metrics.log
```
