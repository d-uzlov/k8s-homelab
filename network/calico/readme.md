
Set up cluster networking
```bash
# wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml

kl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kl apply -f ./network/calico/calico-custom-resources.yaml

# maybe we could need this for BGP but I disabled it
# kl set env daemonset/calico-node -n calico-system IP_AUTODETECTION_METHOD=interface=ens18

kl wait -n calico-system --for=condition=ready pods --all
kl wait -n calico-apiserver --for=condition=ready pods --all
```
