
# prerequisites:

- [control plane](./control-plane.md)
- Have cluster CA key in local filesystem
- [node dependencies](./node-dependencies.md)

# ansible inventory

You need to add your k8s nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
worker-1:
  ansible_host: worker-1.k8s.lan
  ansible_python_interpreter: auto_silent
  # same as in control plane config
  k8s_apiserver_loadbalancer_endpoint: k8s-example-cp.example.com
  # must be the same as value in control plane nodes
  k8s_cluster_name: example-cluster
  # how to register node in a cluster
  # may be the same as host address, or it may be different, it's just a matter of preference
  k8s_node_name: worker-1.k8s.lan
  # it's nice to have an ability to run a lot of pods,
  # but if node is low on memory, you may want to lower the limit
  k8s_max_pods: 250
  # good value for k8s_kube_reserved_memory can be estimated as (10Mi * max_pods)
  k8s_kube_reserved_memory: 2500Mi
```

# deploy

```bash

ansible-inventory --graph kubelet

# install/update on a single new node
ansible-playbook ./k8s-core/docs/ansible/node-kubelet-playbook.yaml --limit worker-1

# update kubelet or config on all nodes
# (check on a single node to make sure nothing breaks before running)
ansible-playbook ./k8s-core/docs/ansible/node-kubelet-playbook.yaml

```

# upgrade

Download new versions of tools in [dependencies](./node-dependencies.md).

Then simply run the playbook. No special actions needed.
