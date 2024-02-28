
# homarr

References:
- https://github.com/bastienwirtz/homer
- https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md
- https://hub.docker.com/r/b4bz/homer

# Deploy

```bash
kl create ns homer
kl label ns homer pod-security.kubernetes.io/enforce=baseline

# ingress with wildcard certificate
kl label ns --overwrite homer copy-wild-cert=main
kl apply -k ./board/homer/ingress-wildcard/
kl -n homer get ingress

kl apply -k ./board/homer/pvc/
kl -n homer get pvc

kl apply -k ./board/homer/
kl -n homer get pod -o wide
```

# Cleanup

```bash
kl delete -k ./board/homer/
kl delete -k ./board/homer/pvc/
kl delete ns homer
```
