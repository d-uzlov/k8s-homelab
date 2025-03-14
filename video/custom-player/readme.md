
# Custom OvenPlayer-based player

References:
- https://airensoft.gitbook.io/ovenplayer/

# Default keys

You can set a list of default keys that are used when page arg list is empty:

```bash

mkdir -p ./video/custom-player/content/env/
 cat << EOF > ./video/custom-player/content/env/data-sources.js
export function getDataSources() {
  const res = {};
  res.main = 'https://ome-streams.domain';
  return res;
}
EOF
# redact this file manually to include all your api-exporter sources

```

If you don't want to use default keys, make the file empty.

If the default keys don't contain something,
you can point the page to required keys
using URL args: `/#sources=source_key1,source_key2`.

# Download libs

You need to have `ovenplayer.js` and `hls.min.js` in your content directory:

```bash

(
    cd ./video/custom-player/content/env/
    [ -f ovenplayer.js ] || wget https://github.com/AirenSoft/OvenPlayer/raw/master/dist/ovenplayer.js
    [ -f hls.min.js ] || {
        wget https://github.com/video-dev/hls.js/releases/download/v1.5.11/release.zip
        unzip -j release.zip dist/hls.min.js
        rm release.zip
    }
)

```

# Deploy

```bash

kl create ns ome-player
kl label ns ome-player pod-security.kubernetes.io/enforce=baseline

kl -n ome-player apply -f ./network/default-network-policies.yaml
kl apply -f ./video/custom-player/network-policy.yaml

# setup wildcard ingress
kl label ns --overwrite ome-player copy-wild-cert=main
kl apply -k ./video/custom-player/ingress-wildcard/
kl -n ome-player get ingress

kl apply -k ./video/custom-player/ingress-route/
kl -n ome-player describe httproute
kl -n ome-player get httproute

kl apply -k ./video/custom-player/ --server-side
kl -n ome-player get pod -o wide

```

# Cleanup

```bash
kl delete -k ./video/custom-player/
kl delete ns ome-player
```
