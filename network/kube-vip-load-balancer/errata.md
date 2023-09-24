
# Lost lease

Completely broken:
- v0.6.0
- v0.6.1

These version loose service leases, and external IPs completely disappear.

These version don't have this issue:
- v0.5.12 and below
- v0.6.2

# externalTrafficPolicy: Local is broken

Requires servicesElection to be broken.

Broken on versions:
- v0.5.12
- v0.6.2

I didn't test versions below v0.5.12.

References:
- https://github.com/kube-vip/kube-vip/issues/608
