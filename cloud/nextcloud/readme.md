
# Nextcloud

References:
- https://github.com/nextcloud/docker
- https://hub.docker.com/_/nextcloud/
- https://github.com/aptible/supercronic
- https://hub.docker.com/_/nginx
- https://chrismoore.ca/2018/10/finding-the-correct-pm-max-children-settings-for-php-fpm/

# Storage setup

Set storage classes for different data types:

```bash

mkdir -p ./cloud/nextcloud/pvc/env/
 cat << EOF > ./cloud/nextcloud/pvc/env/pvc.env
# userdata uses ReadWriteMany type volumes
userdata=fast
userdata_size=1Ti

# config uses ReadWriteMany type volumes
config=fast
config_size=1Gi
EOF

```

# Config setup

Generate passwords and set up config.

```bash

mkdir -p ./cloud/nextcloud/main-app/env/

 cat << EOF > ./cloud/nextcloud/main-app/env/passwords.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
admin_name=admin
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

 cat << EOF > ./cloud/nextcloud/main-app/env/nextcloud.env
# k8s pod CIDR
trusted_proxies=10.201.0.0/16
EOF

```

# deploy

Prerequisites:
- Create namespace first
- [postgres](./postgres-cnpg/readme.md)

```bash

kl create ns nextcloud
kl label ns nextcloud pod-security.kubernetes.io/enforce=baseline

# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/ingress-wildcard/
kl -n nextcloud get ingress

kl apply -k ./cloud/nextcloud/httproute-private/
kl apply -k ./cloud/nextcloud/httproute-public/
kl -n nextcloud get httproute

# tell nextcloud to allow connections via ingress domain address
nextcloud_public_domain=$(kl -n nextcloud get ingress nextcloud -o go-template --template "{{ (index .spec.rules 0).host}}")
kl -n nextcloud create configmap public-domain --from-literal public_domain="*$nextcloud_public_domain*" -o yaml --dry-run=client | kl apply -f -

kl apply -k ./cloud/nextcloud/pvc/
kl -n nextcloud get pvc

kl apply -k ./cloud/nextcloud/main-app/
kl -n nextcloud get pod -o wide

```

TODO support dynamic postgres password update without manual config edits.

# Uninstall

```bash
kl delete -k ./cloud/nextcloud/notifications/
kl delete -k ./cloud/nextcloud/main-app/
kl delete -k ./cloud/nextcloud/pvc/
kl delete ns nextcloud
```

# Apps

TODO

Potentially interesting apps:
- Archive manager
- Contacts
- Draw.io
- Extract
- Full text search (requires external setup)
- Notes
- Recognize

Investigate `allow_local_remote_servers` option.
