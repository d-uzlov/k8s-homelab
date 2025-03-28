
# Homepage

References:
- https://gethomepage.dev/installation/k8s/
- https://github.com/gethomepage/homepage
- https://github.com/gethomepage/homepage/pkgs/container/homepage

# Init configs

```bash

mkdir -p ./board/homepage/config/env/

# ============= Proxmox =============
echo "- Proxmox:" >> ./board/homepage/config/env/services-proxmox.yaml
# any node ip
proxmox_api_endpoint=
# https://gethomepage.dev/latest/widgets/services/proxmox/
proxmox_username=
proxmox_password=
# sum over all cluster nodes
 cat << EOF >> ./board/homepage/config/env/services-proxmox.yaml
  - Cluster:
      icon: proxmox.png
      widget:
        type: proxmox
        url: https://$proxmox_api_endpoint:8006
        username: $proxmox_username
        password: $proxmox_password
EOF
# statistics for each individual node
readable_node_name=
exact_node_name=
node_address=
 cat << EOF >> ./board/homepage/config/env/services-proxmox.yaml
  - $readable_node_name:
      href: https://$node_address:8006/
      icon: proxmox.png
      widget:
        type: proxmox
        url: https://$proxmox_api_endpoint:8006
        username: $proxmox_username
        password: $proxmox_password
        node: $exact_node_name
EOF

# ============= Truenas =============
echo "- Truenas:" >> ./board/homepage/config/env/services-truenas.yaml
truenas_address=
truenas_api_key=
 cat << EOF >> ./board/homepage/config/env/services-truenas.yaml
  - Truenas SSD:
      href: http://$truenas_address/
      icon: truenas.png
      widget:
        type: truenas
        url: http://$truenas_address
        key: $truenas_api_key
        enablePools: true
        nasType: scale
EOF

# user-facing services
ingress_domain_suffix=
sed -e "s|AUTOMATIC_REPLACE_DOMAIN_SUFFIX|$ingress_domain_suffix|g" \
  ./board/homepage/config/services-user.tmpl.yaml \
  >> ./board/homepage/config/env/services-user.yaml

```

Manually edit `./board/homepage/config/env/services-*`
to account for your local environment.

# Deploy

```bash

kl create ns homepage
kl label ns homepage pod-security.kubernetes.io/enforce=baseline

# regenerate config after any changes
# Rename files lexicographically to change its order in the page.
cat ./board/homepage/config/env/services-*.yaml > ./board/homepage/config/env/services.yaml && kl apply -k ./board/homepage/config/

kl apply -k ./board/homepage/
kl -n homepage get pod -o wide

kl apply -k ./board/homepage/httproute-private/
kl apply -k ./board/homepage/httproute-protected/
kl -n homepage get httproute
kl -n homepage describe httproute

```

# Cleanup

```bash
kl delete -k ./board/homepage/httproute-protected/
kl delete -k ./board/homepage/httproute-private/
kl delete -k ./board/homepage/
kl delete ns homepage
```
