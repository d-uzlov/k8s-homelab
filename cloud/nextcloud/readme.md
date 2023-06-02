
# deploy

```bash
kl create ns nextcloud
kl label ns --overwrite nextcloud copy-wild-cert=example
kl label ns --overwrite nextcloud onlyoffice.replicator.io/api=
kl label ns --overwrite nextcloud onlyoffice.replicator.io/public-domain=

# Init once
cat <<EOF > ./cloud/nextcloud/env/mariadb.env
root_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
user_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
user_name=nextcloud
db_name=nextcloud
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/nextcloud.env
admin_name=admin
admin_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/redis.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/nextcloud.env
# Space-separated list of domaind. Wildcard is allowed in any place.
# frontend.*.svc is required for onlyoffice integration
trusted_domains=*.example.duckdns.org frontend.*.svc
# k8s pod CIDR
trusted_proxies=10.201.0.0/16
EOF
# Init once
cat <<EOF > ./cloud/nextcloud/env/ingress.env
# host used in ingress
public_domain=nextcloud.example.duckdns.org

# set to value specified in ingress/manual-certificates/<your-cert>
wildcard_secret_name=wild--example.duckdns.org

# Limit access from web, or leave empty
# Comma-separated list of CIDRs
ingress_allowed_sources=10.0.0.0/16,1.2.3.4,1.2.3.4
EOF

kl apply -k ./cloud/nextcloud/pvc/
kl apply -k ./cloud/nextcloud/
```

# Uninstall

```bash
kl delete -k ./cloud/nextcloud/
kl delete -k ./cloud/nextcloud/pvc/
```

# PHP settings

env `PHP_INI_DIR`

Check php config:
kl -n nextcloud exec deployments/nextcloud -it -- php -i

# Changing PHP-FPM settings

Find where config files are located:
kl -n nextcloud exec deployments/nextcloud -it -- cat /usr/local/etc/php-fpm.conf | grep include -C 5
kl -n nextcloud exec deployments/nextcloud -it -- ls /usr/local/etc/php-fpm.d/ -la

Verify that config really changed:
kl -n nextcloud exec deployments/nextcloud -it -- php-fpm -tt | grep pm

# Adjust chunk size on Nextcloud side

For upload performance improvements in environments with high upload bandwidth, the server’s upload chunk size may be adjusted:

```bash
sudo -u www-data php occ config:app:set files max_chunk_size --value 20971520
```
Put in a value in bytes (in this example, 20MB). Set --value 0 for no chunking at all.
Default is 10485760 (10 MiB).

Don't forget to update ingress settings for max client body size.

# Speed testing

Via router ip:
nfs-bulk:
upload 15 МБ/с
download 20 МБ/с

Via load balancer ip:
iscsi performance:
upload 60 MB/s, download 115 MB/s (capped at the link speed)

nfs performance:
upload 40 MB/s, download 65 MB/s

# Temp file location

https://docs.nextcloud.com/server/16/admin_manual/configuration_server/config_sample_php_parameters.html#all-other-configuration-options

'tempdirectory' => '/tmp/nextcloudtemp',
Override where Nextcloud stores temporary files. Useful in situations where the system temporary directory is on a limited space ramdisk or is otherwise restricted, or if external storages which do not support streaming are in use.

The Web server user must have write access to this directory.

# Bruteforce protection FAQ

https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#security

```bash
# list throttled ips
kl -n nextcloud exec deployments/mariadb -- mysql -u nextcloud -pnextcloud --database nextcloud -e "select * from oc_bruteforce_attempts;"
# unblock an ip-address
php /var/www/html/occ security:bruteforce:reset <ip-address>
# enable a disabled user
php /var/www/html/occ user:enable <name of user>
```

# Apps

Potentially interesting apps:
Archive manager
Contacts
Draw.io
Extract
Full text search (requires external setup)
Notes
Recognize

# Push notifications useful commands

```bash
# self-test
php /var/www/html/occ notify_push:self-test
# show number of connections and messages
php /var/www/html/occ notify_push:metrics
# send a test notifications to used with id "admin"
php /var/www/html/occ notification:test-push admin
```

Mobile app should register itself when connecting to server.
If you sign out and login again then it seems like it doesn't.
This can be fixed by clearing mobile app data.

# List available occ commands

```bash
# list all commands
php /var/www/html/occ list
# show current config for all apps
kl -n nextcloud exec deployments/nextcloud -it -- php /var/www/html/occ config:list > config-list.json
# show current config for onlyoffice
kl -n nextcloud exec deployments/nextcloud -it -- php /var/www/html/occ config:list onlyoffice
```

# TODO

https://github.com/nextcloud/all-in-one/blob/ee06a04f5191628691c843af667143aa1a163256/Containers/nextcloud/entrypoint.sh

Full text search

Test S3 speed?

Check out Memories app:
https://github.com/pulsejet/memories/
https://www.reddit.com/r/NextCloud/comments/z246f7/memories_google_photos_alternative_for_nextcloud/

Imaginary for preview generation:
https://github.com/nextcloud/previewgenerator
https://docs.nextcloud.com/server/24/admin_manual/installation/server_tuning.html#previews
https://github.com/nextcloud/all-in-one/blob/ee06a04f5191628691c843af667143aa1a163256/Containers/nextcloud/entrypoint.sh#L255

Use proper app checks instead of just checking that app folder exists.

Use NFS for the main app dir?
https://www.google.com/search?q=php+nfs+slow&ei=NF26WLb0HJCIyAW43YzQAg&gws_rd=cr&fg=1&hl=en
