
# Custom OvenPlayer-based player

References:
- https://airensoft.gitbook.io/ovenplayer/

# Default keys

You can set a list of default keys that are used when page arg list is empty:

```bash
mkdir -p ./video/custom-player/content/env/
cat << EOF > ./video/custom-player/content/env/key.list
'key','another_key'
EOF
```

If you don't want to use default keys, make the file empty.

# Deploy

```bash
kl create ns ome-player

# setup wildcard ingress
kl label ns --overwrite ome-player copy-wild-cert=main
kl apply -k ./video/custom-player/ingress-wildcard/
kl -n ome-player get ingress

ome_public_domain=$(kl -n ome get ingress signal -o go-template --template "{{range .spec.rules}}{{.host}}{{end}}")
sed \
    -e "s/AUTOREPLACE_SIGNAL_DOMAIN/$ome_public_domain/" \
    -e "s/AUTOREPLACE_DEFAULT_STREAM_KEYS/$(cat ./video/custom-player/content/env/key.list)/" \
    ./video/custom-player/content/get-domain.js.template \
    > ./video/custom-player/content/env/get-domain.js

kl apply -k ./video/custom-player/
kl -n ome-player get pod -o wide
```

# Cleanup

```bash
kl delete -k ./video/custom-player/
kl delete ns ome-player
```
