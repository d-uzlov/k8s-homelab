
# install

```bash

ETCD_VER=v3.5.22
etcd_file=etcd-${ETCD_VER}-linux-amd64.tar.gz
wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/$etcd_file" -O ./k8s-core/docs/etcd/env/$etcd_file
mkdir -p ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/
tar zxf ./k8s-core/docs/etcd/env/$etcd_file -C ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/
sudo mv ./k8s-core/docs/etcd/env/etcd-$ETCD_VER/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
etcdctl version

```

# Setup aliases

```bash

cluster_name=
node1=etcd1.k8s.lan
node2=etcd2.k8s.lan
node3=etcd3.k8s.lan

 cat << EOF > ~/.bashrc.d/etcd-aliases.sh
# you may want to add this to your bashrc
alias etcdctl_cluster="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:2379,https://$node2:2379,https://$node3:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node1="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node1:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node2="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node2:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"

alias etcdctl_node3="ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints=https://$node3:2379 \
  --cacert=./k8s-core/docs/etcd/env/config-$cluster_name/ca.pem \
  --cert=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client.pem \
  --key=./k8s-core/docs/etcd/env/config-$cluster_name/etcd-client-key.pem"
EOF

```

# Test connection

```bash

etcdctl_cluster member list -w table
etcdctl_cluster endpoint status -w table
etcdctl_cluster endpoint health -w table

```

# Disaster recovery

Imagine `etcd1.k8s.lan` is unavailable.
Cluster is still working but is unhealthy.
You need to replace it with a new node, or just reinitialize the old one.
The process is the same for both cases.

Adjust node names and addresses appropriately.

```bash

etcdctl_cluster member list -w table
# replace ID with your value
etcdctl_cluster member remove b5a71f0b96b3191f
etcdctl_cluster member list -w table

# Choose any name.
# Here I reuse the old name because I re-init the old node.
# Set correct URL for your new node.
etcdctl_cluster member add etcd1.k8s.lan --peer-urls=https://etcd1.k8s.lan:2380

# change --initial-cluster-state=new to --initial-cluster-state=existing in docker-compose.yml
# On an existing failed node you also need to remove the old data folder.
cd /opt/etcd/
sudo docker compose down
sudo nano ./docker-compose.yml
sudo rm -r /opt/etcd/data/
sudo docker compose up

```

# Shrink etcd DB

```bash

etcdctl_cluster endpoint status --write-out=json | jq .
# check database size
etcdctl_cluster endpoint status --write-out=json | jq .[].Status.dbSize | numfmt --to=iec

# get current cluster revision
etcdctl_cluster endpoint status --write-out=json | jq .[].Status.header.revision
# substitute your revision
etcdctl_cluster compact 816183644

# defrag one node at a time
etcdctl_node1 defrag
etcdctl_node2 defrag
etcdctl_node3 defrag

```
