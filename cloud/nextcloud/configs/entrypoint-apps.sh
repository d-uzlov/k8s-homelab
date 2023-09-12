#!/bin/sh
set -eu

trap : TERM INT

# This script runs on each app restart

umask 0

# sleep infinity

if [ ! -z "${ONLYOFFICE_PASSWORD:-}" ]; then
    echo "Onlyofficce app..."
    if [ ! -d "/var/www/html/custom_apps/onlyoffice/" ]; then
        echo "Onlyofficce app: install"
        php /var/www/html/occ app:install onlyoffice
    elif [ "$(php /var/www/html/occ config:app:get onlyoffice enabled)" != "yes" ]; then
        echo "Onlyofficce app: enable"
        php /var/www/html/occ app:enable onlyoffice
    else
        echo "Onlyofficce app: update"
        php /var/www/html/occ app:update onlyoffice
    fi

    echo "Onlyofficce app: set settings"
    php /var/www/html/occ config:system:set onlyoffice DocumentServerUrl --value="https://${ONLYOFFICE_PUBLIC_DOMAIN}/"
    php /var/www/html/occ config:system:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice.${ONLYOFFICE_NAMESPACE}.svc/"
    php /var/www/html/occ config:system:set onlyoffice StorageUrl --value="http://frontend.${NAMESPACE}.svc/"
    php /var/www/html/occ config:system:set onlyoffice jwt_header --value="${ONLYOFFICE_HEADER}"
    php /var/www/html/occ config:system:set onlyoffice jwt_secret --value="${ONLYOFFICE_PASSWORD}"

    php /var/www/html/occ config:app:set onlyoffice customizationFeedback --value="false"
else
    echo "Skipping onlyoffice setup because password is not defined"
    php /var/www/html/occ app:disable onlyoffice || true
fi

# -------------------

echo "Notify push app..."
if ! [ -d "/var/www/html/custom_apps/notify_push" ]; then
    echo "Notify push app: install"
    php /var/www/html/occ app:install notify_push
elif [ "$(php /var/www/html/occ config:app:get notify_push enabled)" != "yes" ]; then
    echo "Notify push app: enable"
    php /var/www/html/occ app:enable notify_push
else
    echo "Notify push app: update"
    php /var/www/html/occ app:update notify_push
fi

# -------------------

echo "DB maintenance..."
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#add-missing-indices
echo "Add missing indices"
php /var/www/html/occ db:add-missing-indices
