
# Deploy

```bash
kl apply -k ./test/ingress
kl apply -k ./test/ingress/wildcard
kl apply -k ./test/ingress/http01/
```

# Cleanup

```bash
kl delete -k ./test/ingress/wildcard
kl delete -k ./test/ingress/http01/
kl delete -k ./test/ingress
```
