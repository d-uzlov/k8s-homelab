
# kubectl tips

This file describes various useful kubectl commands.

# Bash completion

References:
- [kubectl bash completion](../bash.md#kubectl-completion)

# Delete failed pods

During graceful shutdown k8s likes to create a myriad of pods in a `Failed` state,
that couldn't run because the node was shutting down. Duh.

These pods remain in the list even after cluster has rebooted and all working pods are scheduled.

```bash
# show pods
kl get pods --field-selector status.phase=Failed --all-namespaces
kl get pods --field-selector status.phase=Succeeded --all-namespaces

# delete pods
kl delete pods --field-selector status.phase=Failed --all-namespaces
kl delete pods --field-selector status.phase=Succeeded --all-namespaces
```

# Show pods from a certain node

```bash
kl get pod -A --field-selector spec.nodeName=n100.k8s.lan
```
