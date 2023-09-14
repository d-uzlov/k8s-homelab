
# Nextcloud

References:
- https://github.com/nextcloud/docker
- https://hub.docker.com/_/nextcloud/

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
mkdir -p ./cloud/nextcloud/env/
cat <<EOF > ./cloud/nextcloud/main-app/env/mariadb.env
root_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
user_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
user_name=nextcloud
db_name=nextcloud
EOF
cat <<EOF > ./cloud/nextcloud/main-app/env/nextcloud.env
admin_name=admin
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
cat <<EOF > ./cloud/nextcloud/main-app/env/redis.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
cat <<EOF > ./cloud/nextcloud/main-app/env/settings.env
# k8s pod CIDR
trusted_proxies=10.201.0.0/16
EOF
```

# Deploy

```bash
kl create ns nextcloud

kl apply -k ./cloud/nextcloud/pvc/
kl -n nextcloud get pvc

kl apply -k ./cloud/nextcloud/main-app/
kl -n nextcloud get pod

# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/ingress-wildcard/
kl -n nextcloud get ingress

# nextcloud needs you to set public domain in settings
nextcloud_public_domain=$(kl -n nextcloud get ingress nextcloud -o go-template --template="{{range .spec.rules}}{{.host}}{{end}}")
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php /var/www/html/occ config:system:set trusted_domains 1 --value "${nextcloud_public_domain}"
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php /var/www/html/occ config:app:set notify_push base_endpoint --value="https://${nextcloud_public_domain}/push"
```

# Setup onlyoffice

TODO

```bash
kl label ns --overwrite nextcloud onlyoffice.replicator.io/api=
kl label ns --overwrite nextcloud onlyoffice.replicator.io/public-domain=
```

# Uninstall

```bash
kl delete -k ./cloud/nextcloud/ingress-wildcard/
kl delete -k ./cloud/nextcloud/main-app/
kl delete -k ./cloud/nextcloud/pvc/
kl delete ns nextcloud
```

# Brute-force protection FAQ

Nextcloud will temporarily lock you out of web UI if you fail several login attempts.

You can reset this:

```bash
# list throttled ips
kl -n nextcloud exec deployments/mariadb -- mysql -u nextcloud -pnextcloud --database nextcloud -e "select * from oc_bruteforce_attempts;"
# unblock an ip-address
php /var/www/html/occ security:bruteforce:reset <ip-address>
# enable a disabled user
php /var/www/html/occ user:enable <name of user>
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

# Push notifications useful commands

Nextcloud supports push notifications.
Notifications should work both in web browsers and in the mobile app.

Push notifications require an external setup to work.
You can run test commands to check if you set it up correctly.

```bash
# self-test
php /var/www/html/occ notify_push:self-test
# show number of connections and messages
php /var/www/html/occ notify_push:metrics
# send a test notifications to used with id "admin"
php /var/www/html/occ notification:test-push admin
```

**Note**: Mobile app should register itself when connecting to server.
If you sign out and login again then it seems like it doesn't.
This can be fixed by clearing mobile app data.
