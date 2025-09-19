
# k8s control plane

In an on-prem environment (development, homelab, etc.)
k8s cluster is typically created using some one-click tool: kubeadm, k0s, micro-k3s, etc.

In such a setup the k8s control plane usually runs on a control-plane node,
which is guarded by `node-role.kubernetes.io/control-plane` taint.

However, in managed k8s clusters control plane is often not part of the cluster.
There are no `control-plane` nodes in the cluster,
and there are no pods for apiserver, scheduler, or controller-manager.

This guide also follows approach where essential k8s components are out of the cluster.

Technically, control plane components don't need to run on the same host.
But I don't really see a benefit in running them on separate nodes either,
so we will be running `apiserver` + `controller-manager` + `scheduler` combo on each node.

# reasoning

There are a few reasons to abandon the kubeadm and other approaches.

1. While one-click tools are very convenient and quick to setup, they are not very flexible.
When using kubeadm I was feeling how I fight with it for every change in configuration.

Do you want node-specific kubelet config?
No, you can't have it. There is no such thing as node-specific config.
You _can_ dig up things such as `/etc/default/kubelet` file, but it's not very flexible, and not guaranteed to work.
You can also manually edit kubelet service files. But you need to figure out how kubeadm manages them,
and there is no guarantee that the format will not change later.
Each time you upgrade node it will download cluster-wide kubelet config, overwriting any possible local changes.

If you want to change control plane components, you need to use patches.
The patches are not very convenient to use. It's a set of separate files with fixed names.
You need to manually upload them to nodes.
If you ever forget to include `patches` as kubeadm arg, it will overwrite control plane manifests with default ones.

2. For best stability control-plane nodes should not run any custom workloads.
But if control plane nodes are part of the cluster, they _can_ run them, theoretically.
So they need to run infrastructure DaemonSet workloads, such as CNI and CSI plugins.
It's unlikely a plugin will use too much memory or CPU. But you still pay for it.
And some plugins, like democratic-csi, are more resource-intensive than I would like.
Removing such infrastructure daemonsets from control plane nodes would require you to tweak their tolerations,
which is not the work I'm looking forward to do,
_and_ it would compromise them as proper cluster nodes!

3. Do you want to add auth config? You need to copy it manually.
Any other config? Copy it manually.

4. For any non-standard deployment you need to understand inner workings that kubeadm is trying to hide from you.

---

So, if your configuration is not following the very rigid standard
it doesn't make much sense to use kubeadm, IMo.

# inspiration

References:
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- The primary source: https://github.com/ghik/kubernetes-the-harder-way/tree/linux
- https://kubernetes.io/docs/setup/best-practices/certificates/

# prerequisites

- [external etcd setup](../etcd/etcd.md)
- [cluster CA](./control-plane-ca.md)
- [cfssl](../../../docs/cfssl.md)

# generate config for node components

```bash

cluster_name=

# unlike CA folder, pki folder is effectively disposable,
# nothing will break if you delete it
mkdir -p ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/

cfssl gencert \
  -ca=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem \
  -ca-key=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem \
  -config=./k8s-core/docs/ansible/csr/ca-config.json \
  -profile=kubernetes \
  ./k8s-core/docs/ansible/csr/service-accounts.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/service-accounts

etcd_cluster_name=
cp ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/ca.pem ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/etcd-ca.pem
cp ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/etcd-client.pem ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/etcd-client.pem
cp ./k8s-core/docs/etcd/env/config-$etcd_cluster_name/etcd-client-key.pem ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/etcd-client-key.pem

# initialize empty auth config if it's missing

 [ -f k8s-core/docs/ansible/env/cluster-$cluster_name/auth-config.yaml ] || cat << EOF > ./k8s-core/docs/ansible/env/cluster-$cluster_name/auth-config.yaml
---
apiVersion: apiserver.config.k8s.io/v1beta1
kind: AuthenticationConfiguration
jwt: []
EOF

```

# ansible inventory

You need to add your control plane nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
control-plane-1:
  ansible_host: control-plane-1.example.com
  ansible_python_interpreter: auto_silent
  # cluster name is used to separate folder structure of different clusters
  k8s_cluster_name: example-cluster
  k8s_apiserver_advertise_address: 10.3.1.2
  k8s_apiserver_etcd_endpoints: https://etcd1.example.com.:2379,https://etcd2.example.com.:2379,https://etcd3.example.com.:2379
  k8s_apiserver_loadbalancer_endpoint: k8s-example-cp.example.com
  k8s_cluster_service_cidr: 10.202.0.0/16
  k8s_cluster_kubernetes_svc_ip: 10.202.0.1
  # pod CIDR may be meaningless depending on your CNI choice and config
  # but kube-controller-manager still needs it
  k8s_cluster_pod_cidr: 10.201.0.0/16
  # you are expected to point k8s_apiserver_loadbalancer_endpoint to this virtual IP
  keepalived_apiserver_virtual_ip: 10.3.0.255
  keepalived_apiserver_virtual_ip_prefix: 16
  # random number in range [1, 255], must be the same for all instances holding an address
  keepalived_apiserver_virtual_router_id: 87
```

Note that each control plane host must have its own `k8s_apiserver_advertise_address`,
but all other options will be shared between hosts in a cluster.

You will need to re-run the playbook whenever control plane host IP is changed.

# deploy

First make sure that each host has docker:
- [docker.md](../../../docs/docker/docker.md)

```bash

ansible-inventory --graph k8s_control_plane

ansible-playbook ./k8s-core/docs/ansible/control-plane-apiserver-playbook.yaml --limit control-plane-1
ansible-playbook ./k8s-core/docs/ansible/control-plane-scheduler-playbook.yaml --limit control-plane-1
ansible-playbook ./k8s-core/docs/ansible/control-plane-controller_manager-playbook.yaml --limit control-plane-1

# this allows apiserver to talk to kubelets
kl create clusterrolebinding system:cluster-admins --clusterrole cluster-admin --group cluster-admins

```

Apiserver needs to be able to talk to pods for webhooks and Aggregation API.

You either need to ensure L3 connectivity from apiserver host to pod network,
or deploy something like konnectivity proxy:

- https://kubernetes.io/docs/tasks/extend-kubernetes/setup-konnectivity/

# teardown control plane host

```bash

ansible-playbook ./k8s-core/docs/ansible/control-plane-teardown-playbook.yaml --limit control-plane-1

```

# Next actions

- generate admin kubeconfig
- [join worker nodes](./node.md)
- [CSR approver](../../kubelet-csr-approver/readme.md)
- install CoreDNS (not covered here yet)
- Install CNI
- - [cilium](../../../network/cilium/readme.md) (recommended)
- Advanced auth: [auth-oidc.md](../auth-oidc.md)

# upgrade

Change image version in docker-compose files.
Run the control plane playbooks, preferably one node at a time.
