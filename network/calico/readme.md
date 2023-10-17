
# Calico

References:
- https://github.com/projectcalico/calico

# Install operator

```bash
# Install CRDs
kl apply -k ./network/calico/crds --server-side=true &&
# Deploy Calico using an operator
kl create ns tigera-operator &&
kl apply -k ./network/calico/operator
kl -n tigera-operator get pod -o wide
```

# Install standard version

```bash
kl apply -f ./network/calico/installation-default.yaml

# wait for all pods to be ready
kl -n calico-system get pod -o wide
kl -n calico-apiserver get pod -o wide
```

# Install eBPF version

```bash
# Local init
cat <<EOF > ./network/calico/cm/env/api.env
KUBERNETES_SERVICE_HOST=kcp.lan
KUBERNETES_SERVICE_PORT=6443
EOF

kl apply -k ./network/calico/cm
# reload operator after applying cm
kl -n tigera-operator delete pod --all

kl apply -f ./network/calico/installation-ebpf.yaml

# wait for all pods to be ready
kl -n calico-system get pod -o wide
kl -n calico-apiserver get pod -o wide

# enable Direct Server Return
kl patch felixconfiguration default --type=merge --patch='{"spec": {"bpfExternalServiceMode": "DSR"}}'

# disable kube-proxy
kl -n kube-system patch ds kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"enable-kube-proxy": "true"}}}}}'
# revert rebu-proxy if something goes wrong
kl -n kube-system patch ds kube-proxy --type=json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/enable-kube-proxy"}]'
```

# Cleanup

```bash
kl delete -f ./network/calico/installation-default.yaml
```

Calico doesn't clean up anything after you uninstall it.
Especially if you just do `kubeadm reset`,
without removing calico before destroying the cluster.

Here is a short script that attempts to remove everything related to Calico.

Other CNI plugins will likely need something similar.

```bash
sudo ipvsadm --clear &&
sudo rm -rf /etc/cni &&
sudo rm -rf /var/lib/cni &&
sudo rm -rf /opt/cni &&
sudo rm -rf /var/lib/calico &&
sudo rm -rf /etc/calico &&
(sudo rm -rf /var/run/calico 2> /dev/null || true) &&
(sudo rm -rf /run/calico 2> /dev/null || true) &&
sudo ip route flush proto bird &&
ip link list | grep cali | awk '{print $2}' | cut -c 1-15 | sudo xargs -I {} ip link delete {} &&
sudo iptables-save | grep -i cali | sudo iptables -F &&
sudo iptables-save | grep -i cali | sudo iptables -X &&
sudo iptables -S

# If you `kubeadm reset` and then `kubeadm init` without reboot
# new k8s installation will never detect CNI,
# and all pods will be stuck in Pending state
sudo systemctl reboot
```

# Modify existing installation to use aBPF

https://docs.tigera.io/calico/latest/operations/ebpf/enabling-ebpf

```bash
kl apply -k ./network/calico/cm
kl apply -f ./network/calico/api-server-cm.yaml
kl -n tigera-operator delete pod --all

# check that config map successfully applied
kl -n calico-system logs deployments/calico-typha | grep KUBERNETES_SERVICE_HOST

# patch calico
kl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"linuxDataplane":"BPF", "hostPorts":null}}}'

# enable Direct Server Return
kl patch felixconfiguration default --patch='{"spec": {"bpfExternalServiceMode": "DSR"}}'

# disable kube-proxy
kl -n kube-system patch ds kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'
# revert
kl -n kube-system patch ds kube-proxy --type=json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-calico"}]'
```
