
# homarr

References:
- https://github.com/ajnart/homarr
- https://homarr.dev/docs/introduction/installation
- https://github.com/ajnart/homarr/pkgs/container/homarr

# Deploy

```bash
kl create ns homarr

kl apply -k ./board/homarr/pvc/
kl -n homarr get pvc

# ingress with wildcard certificate
kl label ns --overwrite homarr copy-wild-cert=main
kl apply -k ./board/homarr/ingress-wildcard/
kl -n homarr get ingress

kl apply -k ./board/homarr/
kl -n homarr get pod
```
