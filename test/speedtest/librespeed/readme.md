
# librespeed

References:
- https://github.com/librespeed/speedtest
- https://github.com/librespeed/speedtest

# Deploy

```bash
kl create ns librespeed

# setup wildcard ingress
kl label ns --overwrite librespeed copy-wild-cert=main
kl apply -k ./test/speedtest/librespeed/ingress-wildcard/
kl -n librespeed get ingress

# setun loadbalancer
kl apply -k ./test/speedtest/librespeed/loadbalancer/
kl -n librespeed get svc lb

kl apply -k ./test/speedtest/librespeed/
kl -n librespeed get pod
```

List of results can be found here:
https://librespeed.example.duckdns.org/results/stats.php?op=id&id=

# Cleanup

```bash
kl delete -k ./test/speedtest/librespeed/
kl delete ns librespeed
```
