
# Set up your local environment

Define CIDR or range of IPs that LoadBalancer services are allowed to use:

```bash
mkdir -p ./network/metallb/env/
cat <<EOF > ./network/metallb/env/ip-pool.env
pool=10.0.2.0/24
EOF
```

# Deploy

```bash
kl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
kl -n metallb-system get pod
kl apply -k ./network/metallb/
```

# Remove

```bash
kl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
```

# Test

References:
- [ingress example](../../test/ingress/readme.md)
