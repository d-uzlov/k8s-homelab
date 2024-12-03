
# Restreamer

References:
- https://docs.datarhei.com/restreamer/installing/linux
- https://hub.docker.com/r/datarhei/restreamer
- https://github.com/datarhei/restreamer

# Deploy

```bash
kl create ns restreamer

# create loadbalancer service
kl apply -k ./video/restreamer/loadbalancer/
# get assigned IP to set up DNS or NAT port-forwarding
kl -n restreamer get svc

# setup wildcard ingress
kl label ns --overwrite restreamer copy-wild-cert=main
kl apply -k ./video/restreamer/ingress-wildcard/
kl -n restreamer get ingress

kl apply -k ./video/restreamer/
kl -n restreamer get pod
```

This deployment is unfinished because it introduces ~6-7s of latency to stream, which I consider unusable.
