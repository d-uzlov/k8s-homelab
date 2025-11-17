
# dependencies

```bash

# check out the latest stable release
echo $(curl -Ls https://dl.k8s.io/release/stable.txt)
# see also: https://kubernetes.io/releases/
# see also: https://kubernetes.io/releases/download/

mkdir -p ./k8s-core/docs/ansible/env/

# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# Check new versions here:
# https://github.com/containerd/containerd/releases

containerd_version=2.1.4
containerd_archive=containerd-$containerd_version-linux-amd64.tar.gz
containerd_url=https://github.com/containerd/containerd/releases/download/v$containerd_version/$containerd_archive

wget $containerd_url -O ./k8s-core/docs/ansible/env/$containerd_archive
mkdir -p ./k8s-core/docs/ansible/env/containerd-$containerd_version/
tar --verbose --extract --directory ./k8s-core/docs/ansible/env/containerd-$containerd_version/ --file ./k8s-core/docs/ansible/env/$containerd_archive
./k8s-core/docs/ansible/env/containerd-$containerd_version/bin/containerd --version

wget https://github.com/containerd/containerd/raw/refs/heads/main/containerd.service -O ./k8s-core/docs/ansible/containerd.service

# Check new versions here:
# https://github.com/opencontainers/runc/releases

runc_version=1.3.2
runc_file=runc-$runc_version.amd64

wget https://github.com/opencontainers/runc/releases/download/v$runc_version/runc.amd64 -O ./k8s-core/docs/ansible/env/$runc_file
chmod +x ./k8s-core/docs/ansible/env/$runc_file
./k8s-core/docs/ansible/env/$runc_file --version

# Check new versions here:
# https://github.com/kubernetes-sigs/cri-tools/releases

crictl_version=v1.34.0
crictl_archive=crictl-$crictl_version-linux-amd64.tar.gz
crictl_url=https://github.com/kubernetes-sigs/cri-tools/releases/download/$crictl_version/$crictl_archive

wget $crictl_url -O ./k8s-core/docs/ansible/env/$crictl_archive
mkdir -p ./k8s-core/docs/ansible/env/crictl-$crictl_version/
tar --verbose --extract --directory ./k8s-core/docs/ansible/env/crictl-$crictl_version/ --file ./k8s-core/docs/ansible/env/$crictl_archive
./k8s-core/docs/ansible/env/crictl-$crictl_version/crictl --version

# sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

kubelet_version=v1.34.1
kubelet_file=kubelet-$kubelet_version.amd64

wget https://dl.k8s.io/$kubelet_version/bin/linux/amd64/kubelet -O ./k8s-core/docs/ansible/env/$kubelet_file
chmod +x ./k8s-core/docs/ansible/env/$kubelet_file
./k8s-core/docs/ansible/env/$kubelet_file --version

# kubeadm_version=v1.34.1
# kubeadm_file=kubeadm-$kubeadm_version.amd64

# wget https://dl.k8s.io/$kubeadm_version/bin/linux/amd64/kubeadm -O ./k8s-core/docs/ansible/env/$kubeadm_file
# chmod +x ./k8s-core/docs/ansible/env/$kubeadm_file
# ./k8s-core/docs/ansible/env/$kubeadm_file version --output short

containerd config default > ./k8s-core/docs/ansible/containerd-config.toml

```

Edit containerd config:

```toml

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
SystemdCgroup = true

[plugins."io.containerd.cri.v1.images".registry]
config_path = "/etc/containerd/certs.d"

```

# ansible inventory

You need to add your k8s nodes into ansible inventory,
and set a few additional parameters.

See example:

```yaml
worker-1:
  ansible_host: worker-1.k8s.lan
  ansible_python_interpreter: auto_silent
  # [optional] name of the folder containing OCI proxy settings
  oci_proxy_id: local-proxy
```

# additional guides

- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- https://github.com/kelseyhightower/kubernetes-the-hard-way/tree/master

# deploy

```bash

ansible-inventory --graph kubelet

ansible-playbook ./k8s-core/docs/ansible/node-dependencies-playbook.yaml
ansible-playbook ./k8s-core/docs/ansible/node-dependencies-playbook.yaml --limit worker-1

```
