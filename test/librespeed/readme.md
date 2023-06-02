
# Deploy

```bash
kl create ns librespeed
kl label ns --overwrite librespeed copy-wild-cert=example

# Init local settings
mkdir -p ./test/librespeed/env
cat <<EOF > ./test/librespeed/env/ingress.env
public_domain=librespeed.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,1.2.3.4
EOF

kl apply -k ./test/librespeed/
```

List of results can be found here:
https://librespeed.example.duckdns.org/results/stats.php?op=id&id=
