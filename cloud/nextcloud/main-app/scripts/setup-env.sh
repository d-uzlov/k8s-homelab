#!/bin/sh
set -eu

echo Set MYSQL config...
php /var/www/html/occ config:system:set dbtype --value mysql
php /var/www/html/occ config:system:set dbname --value "$MYSQL_DATABASE"
php /var/www/html/occ config:system:set dbhost --value "$MYSQL_HOST"
php /var/www/html/occ config:system:set dbuser --value "$MYSQL_USER"
php /var/www/html/occ config:system:set dbpassword --value "$MYSQL_PASSWORD"
php /var/www/html/occ config:system:set dbname --value "$MYSQL_DATABASE"

echo Set redis config...
php /var/www/html/occ config:system:set redis host --value redis
php /var/www/html/occ config:system:set redis password --value "$REDIS_PASSWORD"
php /var/www/html/occ config:system:set redis port --value 6379 --type integer
