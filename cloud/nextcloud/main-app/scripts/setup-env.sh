#!/bin/sh
set -eu

echo Set MYSQL config...
php occ config:system:set dbtype --value mysql
php occ config:system:set dbname --value "$MYSQL_DATABASE"
php occ config:system:set dbhost --value "$MYSQL_HOST"
php occ config:system:set dbuser --value "$MYSQL_USER"
php occ config:system:set dbpassword --value "$MYSQL_PASSWORD"
php occ config:system:set dbname --value "$MYSQL_DATABASE"

echo Set redis config...
php occ config:system:set redis host --value redis
php occ config:system:set redis password --value "$REDIS_PASSWORD"
php occ config:system:set redis port --value 6379 --type integer

# check_data_directory_permissions allows occ and nextcloud to work when data dir is world-readable
# check_data_directory_permissions can't be set via occ because it's a dependency loop
# this file should have been created by pre-install script
# but let's make sure that it exists
echo creating datadir_permissions.config.php...
cat << EOF > /var/www/html/config/datadir_permissions.config.php
<?php
\$CONFIG = array (
    'check_data_directory_permissions' => false
);
EOF

echo "Setting custom config..."
php occ config:system:set loglevel --value 1 --type integer
php occ config:system:set localstorage.umask --value 0 --type integer
php occ config:system:set trusted_domains 0 --value 'frontend.*.svc'
php occ config:system:set trusted_domains 1 --value frontend
php occ config:system:set trusted_domains 2 --value "$PUBLIC_DOMAIN"

php occ config:system:set memcache.local --value "\OC\Memcache\APCu"
php occ config:system:set memcache.locking --value "\OC\Memcache\Redis"
php occ config:system:set memcache.distributed --value "\OC\Memcache\Redis"

echo "Configure settings..."
echo "Set background job to Cron"
php occ background:cron
