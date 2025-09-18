
# create config

```bash

cluster_name=trixie
apiserver_endpoint=cp.k8s.lan

kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/kubelet-bootstrap-kubeconfig.yaml" config set-cluster kubernetes --certificate-authority /var/lib/kubelet/pki/ca.pem --server "https://${apiserver_endpoint}:6443" --tls-server-name kubernetes
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/kubelet-bootstrap-kubeconfig.yaml" config set-credentials user --client-certificate /var/lib/kubelet/pki/kubelet-client-bootstrap.pem --client-key /var/lib/kubelet/pki/kubelet-client-bootstrap-key.pem
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/kubelet-bootstrap-kubeconfig.yaml" config set-context default --cluster kubernetes --user user
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/kubelet-bootstrap-kubeconfig.yaml" config use-context default

```

# ansible inventory

You need to add your control plane nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
trixie-n100:
  ansible_host: worker-1.k8s.lan
  ansible_python_interpreter: auto_silent
  # must be the same as value in control plane nodes
  cluster_name: my-cluster-name
  # how to register node in a cluster
  # may be the same as host address, or it may be different, it's just a matter of preference
  k8s_node_name: worker-1.k8s.lan
  # it's nice to have an ability to run a lot of pods,
  # but if node is low on memory, you may want to limit it
  k8s_max_pods: 250
  # good value for k8s_kube_reserved_memory can be estimated as (10Mi * max_pods)
  k8s_kube_reserved_memory: 500Mi
```

# deploy

```bash

ansible-inventory --graph kubelet

# install/update on a single new node
ansible-playbook ./k8s-core/docs/ansible/k8s-node-kubelet-playbook.yaml --limit worker-1

# update kubelet or config on all nodes
# (check on a single node to make sure nothing breaks before running)
ansible-playbook ./k8s-core/docs/ansible/k8s-node-kubelet-playbook.yaml

```
