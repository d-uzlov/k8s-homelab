
# Nextcloud

References:
- https://github.com/nextcloud/docker
- https://hub.docker.com/_/nextcloud/
- https://github.com/aptible/supercronic
- https://hub.docker.com/_/mariadb
- https://hub.docker.com/_/nginx
- https://chrismoore.ca/2018/10/finding-the-correct-pm-max-children-settings-for-php-fpm/

# Storage setup

Set storage classes for different data types:

```bash
mkdir -p ./cloud/nextcloud/pvc/env/
cat <<EOF > ./cloud/nextcloud/pvc/env/pvc.env
mariadb=block
mariadb_size=1Gi
mariadb_binlog=block
mariadb_binlog_size=1Gi

userdata=fast
userdata_size=1Ti

web=block
web_size=10Gi

config=fast
config_size=100Mi
EOF
```

# Config setup

Generate passwords and set up config.

```bash
mkdir -p ./cloud/nextcloud/main-app/env/
cat <<EOF > ./cloud/nextcloud/main-app/env/passwords.env
mariadb_root_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
mariadb_user_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
admin_name=admin
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
cat <<EOF > ./cloud/nextcloud/main-app/env/nextcloud.env
# k8s pod CIDR
trusted_proxies=10.201.0.0/16
EOF
```

# Deploy

```bash
kl create ns nextcloud

# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/ingress-wildcard/
kl -n nextcloud get ingress

# tell nextcloud to allow connections via ingress domain address
nextcloud_public_domain=$(kl -n nextcloud get ingress nextcloud -o go-template --template "{{range .spec.rules}}{{.host}}{{end}}")
kl -n nextcloud create configmap public-domain --from-literal public_domain="$nextcloud_public_domain" -o yaml --dry-run=client | kl apply -f -

kl apply -k ./cloud/nextcloud/pvc/
kl -n nextcloud get pvc

kl apply -k ./cloud/nextcloud/main-app/
kl -n nextcloud get pod -o wide
```

# Uninstall

```bash
kl delete -k ./cloud/nextcloud/notifications/
kl delete -k ./cloud/nextcloud/main-app/
kl delete -k ./cloud/nextcloud/pvc/
kl delete ns nextcloud
```

# Onlyoffice integration

Nextcloud has integration with Onlyoffice app.
You need to deploy [onlyoffice](../onlyoffice/readme.md)
and configure connection settings to use it.

```bash
onlyoffice_public_domain=$(kl -n onlyoffice get ingress onlyoffice -o go-template --template="{{range .spec.rules}}{{.host}}{{end}}")
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:system:set onlyoffice DocumentServerUrl --value "https://${onlyoffice_public_domain}/"
onlyoffice_jwt_secret=$(kl -n onlyoffice get secret onlyoffice-api --template {{.data.jwt_secret}} | base64 --decode)
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:system:set onlyoffice jwt_secret --value "${onlyoffice_jwt_secret}"
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ app:enable onlyoffice
```

# Push notifications

Nextcloud has push notifications system but it requires additional configuration to work.

Note that push server must be in the `trusted_proxies` CIDR.

References:
- https://github.com/nextcloud/notify_push

```bash
# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/notifications/ingress-wildcard/
kl -n nextcloud get ingress

nextcloud_push_domain=$(kl -n nextcloud get ingress push-notifications -o go-template --template="{{range .spec.rules}}{{.host}}{{end}}")
kl -n nextcloud create configmap push --from-literal push_address="https://${nextcloud_push_domain}" -o yaml --dry-run=client | kl apply -f -

kl apply -k ./cloud/nextcloud/notifications/
kl -n nextcloud get pod -o wide
```

You can run test commands to trigger push notifications manually:

```bash
# self-test
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notify_push:self-test
# show number of connections and messages
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notify_push:metrics
# send a test notifications to used with id "admin"
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notification:test-push admin
```

**Note**: Mobile app should register itself when connecting to server.
If you sign out and login again then it seems like it doesn't.
This can be fixed by clearing mobile app data.

# Brute-force protection FAQ

Nextcloud will temporarily lock you out of web UI if you fail several login attempts.

You can reset this:

```bash
# list throttled ips
db_password=$(kl -n nextcloud get secret -l nextcloud=passwords --template "{{range .items}}{{.data.mariadb_user_password}}{{end}}" | base64 --decode)
kl -n nextcloud exec deployments/mariadb -c mariadb -- mysql -u nextcloud -p"$db_password" --database nextcloud -e "select * from oc_bruteforce_attempts;"
# unblock an ip-address
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ security:bruteforce:reset <ip-address>
# enable a disabled user
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ user:enable <name of user>
```

References:
- https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#security

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
