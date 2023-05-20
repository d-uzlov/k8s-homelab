
Set up cluster networking
```bash
kl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kl wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system
kl apply -f ./network/metallb/metallb-ippool.yaml
```
