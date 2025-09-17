
# k8s control plane

In an on-prem environment (development, homelab, etc.)
k8s cluster is typically created using some one-click tool: kubeadm, k0s, micro-k3s, etc.

In such a setup the k8s control plane usually runs on a control-plane node,
which is guarded by `node-role.kubernetes.io/control-plane` taint.

However, in managed k8s clusters control plane is often not part of the cluster.
There are no `control-plane` nodes in the cluster,
and there are no pods for apiserver, scheduler, or controller-manager.

This guide also follows approach where essential k8s components are out of the cluster.

# reasoning

There are a few reasons to abandon the kubeadm and other approaches.

1. While one-click tools are very convenient and quick to setup, they are not very flexible.
When using kubeadm I was feeling how I fight with it for every change in configuration.

Want node-specific kubelet config?
But there is no such thing as node-specific config.
You _can_ dig up things such as `/etc/default/kubelet` file, but it's not very flexible, and not guaranteed to work.
You can also manually edit kubelet service files. But you need to figure out how kubeadm manages them,
and there is no guarantee that the format will not change later.
Each time you upgrade node it will download cluster-wide kubelet config, overwriting any possible local changes.

If you want to change control plane components, you need to use patches.
The patches are not very convenient to use. It's a set of separate files with fixed names.
You need to manually upload them to nodes.
If you ever forget to include `patches` as kubeadm arg, it will overwrite control plane manifests with default ones.

For best stability control-plane nodes should not run any custom workloads.
But if control plane nodes are part of the cluster, they _can_ run them, theoretically.
So they need to run infrastructure DaemonSet workloads, such as CNI and CSI plugins.
It's unlikely a plugin will use too much memory or CPU. But you still pay for it. And democratic-csi, for example, it more resource-intensive than I would like.
Removing such infrastructure daemonsets from control plane nodes would require you to tweak their tolerations,
which is not the work I'm looking forward to do,
_and_ it would compromise them as proper cluster nodes!

If you want to add auth config, you need to copy it manually.
Any other config? Copy it manually.

For any non-standard deployment you need to understand inner workings anyway.

If you need to do some things manually, automated things are not so convenient,
and it consumes more resources, why use kubeadm?

# inspiration

References:
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- The primary source: https://github.com/ghik/kubernetes-the-harder-way/tree/linux
- https://kubernetes.io/docs/setup/best-practices/certificates/

# prerequisites

- [external etcd setup](../etcd/etcd.md)
- [cluster CA](./cluster-ca.md)

Install dependencies:

```bash

# https://github.com/cloudflare/cfssl/releases
cfssl_version=1.6.5

wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssl_${cfssl_version}_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssl_${cfssl_version}_linux_amd64
wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssljson_${cfssl_version}_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssljson_${cfssl_version}_linux_amd64

chmod +x ./k8s-core/docs/etcd/env/cfssl_${cfssl_version}_linux_amd64
chmod +x ./k8s-core/docs/etcd/env/cfssljson_${cfssl_version}_linux_amd64
sudo cp ./k8s-core/docs/etcd/env/cfssl_${cfssl_version}_linux_amd64 /usr/local/bin/cfssl
sudo cp ./k8s-core/docs/etcd/env/cfssljson_${cfssl_version}_linux_amd64 /usr/local/bin/cfssljson

```

# generate config for node components

Technically, control plane components don't need to run on the same host.
But I don't really see a benefit in running them on separate nodes either,
so we will be running `apiserver` + `controller-manager` + `scheduler` combo on each node.

```bash

cluster_name=

mkdir -p ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/

cp ./k8s-core/docs/ansible/csr/apiserver.template.json ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver-csr.json
echo ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver-csr.json

# now you can open the csr template and adjust the list of possible apiserver names
nano ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver-csr.json
# kubernetes.default.svc.cluster.local and shorter versions are required (unless you want to change default cluster domain)
# cluster.service.ip is also required. Set it to the first IP of cluster service CIDR. For example, 10.202.0.1
# all other names are for your convenience
# it's a good idea to list all possible addresses of apiserver,
# but you will be able to just override tls-server-name in kubeconfig anyway

cfssl gencert \
  -ca=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem \
  -ca-key=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem \
  -config=./k8s-core/docs/ansible/csr/ca-config.json \
  -profile=kubernetes \
  ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver-csr.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver

openssl x509 -noout -in ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/apiserver.pem -text

cfssl gencert \
  -ca=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem \
  -ca-key=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem \
  -config=./k8s-core/docs/ansible/csr/ca-config.json \
  -profile=kubernetes \
  ./k8s-core/docs/ansible/csr/scheduler.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/scheduler

cfssl gencert \
  -ca=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem \
  -ca-key=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem \
  -config=./k8s-core/docs/ansible/csr/ca-config.json \
  -profile=kubernetes \
  ./k8s-core/docs/ansible/csr/controller-manager.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/controller-manager

cfssl gencert \
  -ca=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca.pem \
  -ca-key=./k8s-core/docs/ansible/env/cluster-$cluster_name/ca/ca-key.pem \
  -config=./k8s-core/docs/ansible/csr/ca-config.json \
  -profile=kubernetes \
  ./k8s-core/docs/ansible/csr/service-accounts.json | cfssljson -bare ./k8s-core/docs/ansible/env/cluster-$cluster_name/pki/service-accounts

apiserver_endpoint=cp.k8s.lan

kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/generic-kubeconfig.yaml" config set-cluster kubernetes --certificate-authority /etc/k8s/pki/ca.pem --server "https://${apiserver_endpoint}:6443" --tls-server-name kubernetes
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/generic-kubeconfig.yaml" config set-credentials user --client-certificate /etc/k8s/pki/client.pem --client-key /etc/k8s/pki/client-key.pem
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/generic-kubeconfig.yaml" config set-context default --cluster kubernetes --user user
kubectl --kubeconfig "./k8s-core/docs/ansible/env/cluster-$cluster_name/generic-kubeconfig.yaml" config use-context default

etcd_cluster_name=b2788
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

See here for details on customizing auth config:
- [auth-oidc.md](../auth-oidc.md)

# deploy

```bash

ansible-inventory --graph k8s_control_plane

ansible-playbook ./k8s-core/docs/ansible/k8s-control-plane-playbook.yaml

kl create clusterrolebinding system:cluster-admins --clusterrole cluster-admin --group cluster-admins

```

Apiserver needs to be able to talk to pods for webhooks and Aggregation API.

You either need to ensure L3 connectivity from apiserver host to pod network,
or deploy something like konnectivity proxy:

- https://kubernetes.io/docs/tasks/extend-kubernetes/setup-konnectivity/
