
# Homepage

References:
- https://gethomepage.dev/latest/installation/k8s/

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
sed -e "s|AUTOMATIC_RELACE_DOMAIN_SUFFIX|$ingress_domain_suffix|g" \
  ./board/homepage/config/services-user.tmpl.yaml \
  >> ./board/homepage/config/env/services-user.yaml
```

# Deploy

```bash
kl create ns homepage
kl label ns homepage pod-security.kubernetes.io/enforce=baseline

# re-apply this after any change
cat \
  ./board/homepage/config/env/services-proxmox.yaml \
  ./board/homepage/config/env/services-truenas.yaml \
  ./board/homepage/config/env/services-user.yaml \
  ./board/homepage/config/env/services-network.yaml \
  > ./board/homepage/config/env/services.yaml
kl apply -k ./board/homepage/config/

kl apply -k ./board/homepage/
kl -n homepage get pod -o wide

kl apply -k ./board/homepage/httproute/
kl -n homepage describe httproute
kl -n homepage get httproute
```

# Cleanup

```bash
kl delete -k ./board/homepage/httproute/
kl delete -k ./board/homepage/
kl delete ns homepage
```
