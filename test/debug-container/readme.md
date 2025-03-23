
# Debug container

References:
- https://kubernetes.io/blog/2024/08/22/kubernetes-1-31-custom-profiling-kubectl-debug/
- https://github.com/kubernetes/kubectl/issues/1650

If your workload uses distroless images, you can't just `sh` into container because there is no `sh`.
Or you may need elevated privileges while the container is running as non-root.
In such cases you may have to use debug containers.

```bash

namespace=
podName=
targetContainer=
debugImage=docker.io/alpine:3.17.3

# attach with pod default user
kl -n $namespace debug $podName -it --image $debugImage --container debug --profile sysadmin --target $targetContainer -- sh

# attach with root user
kl -n $namespace debug $podName -it --image $debugImage --container debug --profile sysadmin --target $targetContainer --custom ./test/debug-container/profile.yaml -- sh

# attach to already existing debug container
kl attach $podName -c debug -it -- sh

```
