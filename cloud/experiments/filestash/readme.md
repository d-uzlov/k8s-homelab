

References:
- https://www.filestash.app
- https://github.com/mickael-kerjean/filestash

```bash
kl create ns filestash

kl apply -k ./cloud/filestash/
kl -n filestash get pod

# ingress with wildcard certificate
kl label ns --overwrite filestash copy-wild-cert=main
kl apply -k ./cloud/filestash/ingress-wildcard/
kl -n filestash get ingress
```
