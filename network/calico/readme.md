
Set up cluster networking
```bash
# install operator
kl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml

# install Calico
kl apply -f ./network/calico/installation.yaml

# maybe we could need this for BGP but I disabled it
# kl set env daemonset/calico-node -n calico-system IP_AUTODETECTION_METHOD=interface=ens18

kl wait -n calico-system --for=condition=ready pods --all
kl wait -n calico-apiserver --for=condition=ready pods --all
```

# eBPF

From scratch:
https://docs.tigera.io/calico/latest/operations/ebpf/install

```bash
# modify kubeadm flags (before installation, not after)
kubeadm init --skip-phases=addon/kube-proxy

# modify address in api-server-cm.yaml
```

# Modify existing installation to use aBPF

https://docs.tigera.io/calico/latest/operations/ebpf/enabling-ebpf

```bash
kl apply -f ./network/calico/api-server-cm.yaml
kl patch ds -n kube-system kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'

# check that config mapp successfully applied
kl -n calico-system logs deployments/calico-typha | grep KUBERNETES_SERVICE_HOST

# patch calico
kl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"linuxDataplane":"BPF", "hostPorts":null}}}'

# enable Direct Server Return
kl patch felixconfiguration default --patch='{"spec": {"bpfExternalServiceMode": "DSR"}}'

# disable kube-proxy
kl -n kube-system patch ds kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'
```
