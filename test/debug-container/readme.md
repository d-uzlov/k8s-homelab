
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

# when using "--profile sysadmin" you need namespace to be privileged
kl label ns $namespace pod-security.kubernetes.io/enforce=privileged --overwrite

# attach with pod default user
kl -n $namespace debug $podName -it --image $debugImage --container debug --profile sysadmin --target $targetContainer -- sh

# attach with root user
kl -n $namespace debug $podName -it --image $debugImage --container debug --profile sysadmin --target $targetContainer --custom ./test/debug-container/profile.yaml -- sh

# attach to already existing debug container
kl -n $namespace attach $podName -c debug -it -- sh

tar -cvz -f ./prompp-core.tar.gz ./prompp-core.1

```

# Core dump

Steps to take a core dump of a running process:

- Create debug container running as root and with SYSADMIN capabilities
- Make sure there are debug utilities in it
- Capture core dump
- Transfer core dump out of container
- [optional] Terminate debug container

```bash

# terminal 1: create and hold debug container
kl -n prometheus debug prometheus-prompp-0 -it --image docker.io/alpine:3.17.3 --container debug --profile sysadmin --target prometheus --custom ./test/debug-container/profile.yaml -- sh

# terminal 2:
# install GDB (bash is required but not installed automatically)
kl -n prometheus exec pods/prometheus-prompp-0 -c debug -- apk add gdb bash
# gcore forces you to use file, it can't output to stdout
pid=1
kl -n prometheus exec pods/prometheus-prompp-0 -c debug -- gcore -o ./prompp-core-dump $pid
kl -n prometheus exec pods/prometheus-prompp-0 -c debug -- cat ./prompp-core-dump.$pid > ./prompp-core-dump

```
