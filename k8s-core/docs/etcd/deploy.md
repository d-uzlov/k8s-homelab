
# dependencies

```bash

# install etcdctl
ETCD_VER=v3.5.22
etcd_file=etcd-${ETCD_VER}-linux-amd64.tar.gz
wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/$etcd_file" -O ./k8s-core/docs/etcd/env/$etcd_file
mkdir -p ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/
tar zxf ./k8s-core/docs/etcd/env/$etcd_file -C ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/
sudo mv ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
etcdctl version

# install cfssl
wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64
wget -q --show-progress https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64 -O ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64

chmod +x ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64
chmod +x ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64
sudo cp ./k8s-core/docs/etcd/env/cfssl_1.6.5_linux_amd64 /usr/local/bin/cfssl
sudo cp ./k8s-core/docs/etcd/env/cfssljson_1.6.5_linux_amd64 /usr/local/bin/cfssljson

```

# generate certificates

References:
- https://github.com/justmeandopensource/kubernetes/blob/master/kubeadm-external-etcd/2%20simple-cluster-tls.md
- https://github.com/etcd-io/etcd/blob/main/hack/tls-setup/README.md

```bash

# cluster and node names must correspond to values in ansible inventory
cluster_name=test-etcd
node1=test-etcd.guest.lan
# node2=k8s1-etcd2.k8s.lan
# node3=k8s1-etcd3.k8s.lan
nodes="$node1 $node2 $node3"

cluster_nodes=
 for node in $nodes; do
  cluster_nodes=$cluster_nodes,$node=https://$node:2380
done
cluster_nodes="${cluster_nodes:1}"
echo $cluster_nodes

cluster_token=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)

mkdir -p ./k8s-core/docs/etcd/env/config-$cluster_name/

 for node in $nodes; do
cat << EOF > ./k8s-core/docs/etcd/env/config-$cluster_name/$node-etcd.env
NODE_ADDRESS=https://$node:2380
NODE_NAME=$node
CLUSTER_NODES=$cluster_nodes
CLUSTER_TOKEN=$cluster_token
EOF
done

cfssl gencert -initca ./k8s-core/docs/etcd/ca-csr.json | cfssljson -bare ./k8s-core/docs/etcd/env/config-$cluster_name/ca

 for node in $nodes; do
 cat << EOF > ./k8s-core/docs/etcd/env/config-$cluster_name/$node-csr.json
{
  "CN": "etcd",
  "hosts": [
    "localhost",
    "127.0.0.1",
    "${node}"
  ],
  "key": {
    "algo": "ecdsa",
    "size": 384
  },
  "names": [
    {
      "O": "Kubernetes",
      "OU": "etcd"
    }
  ]
}
EOF

cfssl gencert \
  -ca ./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  -ca-key ./k8s-core/docs/etcd/env/config-$cluster_name/ca-key.pem \
  -config ./k8s-core/docs/etcd/ca-config.json \
  -profile=etcd \
  ./k8s-core/docs/etcd/env/config-$cluster_name/$node-csr.json \
  | cfssljson -bare ./k8s-core/docs/etcd/env/config-$cluster_name/$node-etcd-peer

done

cfssl gencert \
  -ca ./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  -ca-key ./k8s-core/docs/etcd/env/config-$cluster_name/ca-key.pem \
  -config ./k8s-core/docs/etcd/ca-config.json \
  -profile=etcd \
  ./k8s-core/docs/etcd/env/config-$cluster_name/$node-csr.json \
  | cfssljson -bare ./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client

```
