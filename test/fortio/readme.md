
# Deploy

```bash

kl create ns fortio

# setup wildcard ingress
kl label ns --overwrite fortio copy-wild-cert=main
kl apply -k ./test/fortio/ingress-wildcard/
kl -n fortio get ingress

kl apply -k ./test/fortio/
kl -n fortio get pod

```
