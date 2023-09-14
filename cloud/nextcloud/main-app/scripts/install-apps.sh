#!/bin/sh
set -eu

trap : TERM INT

umask 0

if [ ! -d "/var/www/html/custom_apps/onlyoffice/" ]; then
  echo "Onlyofficce app: install..."
  rm -rf /var/www/html/custom_apps/onlyoffice/
  php /var/www/html/occ app:install onlyoffice
  php /var/www/html/occ config:app:set onlyoffice customizationFeedback --value false
  php /var/www/html/occ config:system:set onlyoffice StorageUrl --value "http://frontend.${NAMESPACE}.svc/"
  php /var/www/html/occ config:system:set onlyoffice jwt_header --value AuthorizationJwt

  echo if you want to use onlyoffice app you need to enable it manually
  php /var/www/html/occ app:disable onlyoffice
else
  echo "Onlyofficce app: update..."
  php /var/www/html/occ app:update onlyoffice
fi

# -------------------

echo "Notify push app..."
if ! [ -d "/var/www/html/custom_apps/notify_push/" ]; then
  echo "Notify push app: install..."
  rm -rf /var/www/html/custom_apps/notify_push/
  php /var/www/html/occ app:install notify_push

  echo if you want to use push notifications you need to enable it manually
  php /var/www/html/occ app:disable notify_push
else
  echo "Notify push app: update..."
  php /var/www/html/occ app:update notify_push
fi

# -------------------

echo "DB maintenance..."
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#add-missing-indices
echo "Add missing indices..."
php /var/www/html/occ db:add-missing-indices
