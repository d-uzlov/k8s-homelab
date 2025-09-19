
# cfssl

cfssl is a convenient util for generating certificated.

References:
- https://github.com/cloudflare/cfssl

# install

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
