#!/bin/sh
set -eu

trap : TERM INT

umask 0

if [ ! -d "/var/www/html/custom_apps/onlyoffice/" ]; then
  echo "Onlyofficce app: install..."
  rm -rf /var/www/html/custom_apps/onlyoffice/
  php occ app:install onlyoffice
  php occ config:app:set onlyoffice customizationFeedback --value false
  php occ config:system:set onlyoffice StorageUrl --value "http://frontend.${NAMESPACE}.svc/"
  php occ config:system:set onlyoffice jwt_header --value AuthorizationJwt
  php occ config:system:set onlyoffice DocumentServerInternalUrl --value "http://onlyoffice.onlyoffice.svc/"

  echo if you want to use onlyoffice app you need to enable it manually
  php occ app:disable onlyoffice
else
  echo "Onlyofficce app: update..."
  php occ app:update onlyoffice
fi

# -------------------

echo "DB maintenance..."
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#add-missing-indices
echo "Add missing indices..."
php occ db:add-missing-indices
