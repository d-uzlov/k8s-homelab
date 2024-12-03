
# Lost lease

Some version loose service leases, and external IPs completely disappear.

Completely broken:
- v0.6.0
- v0.6.1

These version don't have this issue:
- v0.5.12 and below
- v0.6.2
- v0.7.2

# `externalTrafficPolicy: Local` is broken when `servicesElection` is enabled

Broken on versions:
- v0.5.12
- v0.6.2
- v0.6.3
- v0.6.4
- v0.7.0
- v0.7.1
- v0.7.2

I didn't test versions below v0.5.12.

Fixed in v0.8.0.

References:
- https://github.com/kube-vip/kube-vip/issues/810
