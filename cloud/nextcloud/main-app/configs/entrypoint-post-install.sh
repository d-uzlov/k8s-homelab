#!/bin/sh
set -eu

# This script runs only once, when fisrt installing Nextcloud

umask 0

echo "Changing config dir permissions..."
chmod g+rw,o+rw -R /var/www/html/config/*

echo "Changing data dir permissions..."
chmod g+rw,o+rw -R "$NEXTCLOUD_DATA_DIR"/*

# occ is broken: it doesn't work without check_data_directory_permissions param
# and there is no way to add via `php occ``
# this fails: php /var/www/html/occ config:system:set check_data_directory_permissions --value="false" --type=boolean
sed -i 's/$CONFIG = array (/$CONFIG = array (\n  '"'"'check_data_directory_permissions'"'"' => false,/' /var/www/html/config/config.php

echo "Setting custom config..."
php /var/www/html/occ config:system:set loglevel --value="1" --type=integer
php /var/www/html/occ config:system:set localstorage.umask --value="0" --type=integer

echo "Set redis config..."
php /var/www/html/occ config:system:set redis host --value="redis"
php /var/www/html/occ config:system:set redis password --value="vepwgsvenvjmcyslnrtu"
php /var/www/html/occ config:system:set redis port --value="6379" --type=integer

php /var/www/html/occ config:system:set memcache.locking --value="\OC\Memcache\Redis"
php /var/www/html/occ config:system:set memcache.distributed --value="\OC\Memcache\Redis"

echo "Configure settings..."
echo "Set background job to Cron"
php /var/www/html/occ background:cron

echo "Post-install script done!"
