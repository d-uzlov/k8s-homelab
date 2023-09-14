#!/bin/sh
set -eu

umask 0

echo "Changing config dir permissions..."
chmod +rw -R /var/www/html/config/*

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
php /var/www/html/occ config:system:set loglevel --value 1 --type integer
php /var/www/html/occ config:system:set localstorage.umask --value 0 --type integer
php /var/www/html/occ config:system:set trusted_domains 0 --value 'frontend.*.svc'
php /var/www/html/occ config:system:set trusted_domains 1 --value frontend

php /var/www/html/occ config:system:set memcache.locking --value "\OC\Memcache\Redis"
php /var/www/html/occ config:system:set memcache.distributed --value "\OC\Memcache\Redis"

echo "Configure settings..."
echo "Set background job to Cron"
php /var/www/html/occ background:cron

exec "$@"
