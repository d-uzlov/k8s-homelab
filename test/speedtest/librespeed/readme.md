
# librespeed

References:
- https://github.com/librespeed/speedtest
- https://hub.docker.com/r/linuxserver/librespeed
- https://github.com/linuxserver/docker-librespeed

# Deploy

```bash
kl create ns librespeed
kl label ns librespeed pod-security.kubernetes.io/enforce=baseline

# setun loadbalancer
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

List of results can be found here:
https://librespeed.example.duckdns.org/results/stats.php?op=id&id=

# Cleanup

```bash
kl delete -k ./test/speedtest/librespeed/httproute/
kl delete -k ./test/speedtest/librespeed/ingress-wildcard/
kl delete -k ./test/speedtest/librespeed/loadbalancer/
kl delete -k ./test/speedtest/librespeed/
kl delete ns librespeed
```
