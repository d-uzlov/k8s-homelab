
# librespeed

References:
- https://github.com/librespeed/speedtest
- https://hub.docker.com/r/linuxserver/librespeed
- https://github.com/linuxserver/docker-librespeed

# Deploy

```bash

mkdir -p ./test/speedtest/librespeed/env/
 cat << EOF > ./test/speedtest/librespeed/env/passwords.env
results_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF

```

```bash

kl create ns librespeed
kl label ns librespeed pod-security.kubernetes.io/enforce=baseline

kl apply -k ./test/speedtest/librespeed/loadbalancer/
kl -n librespeed get svc lb

# setup wildcard ingress
kl label ns --overwrite librespeed copy-wild-cert=main
kl apply -k ./test/speedtest/librespeed/ingress-wildcard/
kl -n librespeed get ingress

kl apply -k ./test/speedtest/librespeed/httproute/
kl -n librespeed get httproute librespeed
kl -n librespeed describe httproute librespeed

kl apply -k ./test/speedtest/librespeed/
kl -n librespeed get pod -o wide

```

List of results can be found at `/results/stats.php` of the server address.

# Cleanup

```bash
kl delete -k ./test/speedtest/librespeed/httproute/
kl delete -k ./test/speedtest/librespeed/ingress-wildcard/
kl delete -k ./test/speedtest/librespeed/loadbalancer/
kl delete -k ./test/speedtest/librespeed/
kl delete ns librespeed
```
