#!/bin/sh
set -eu

umask 0

echo "Changing config dir permissions..."
chmod +rw -R /var/www/html/config/* || true

# /path/to/nextcloud/core/skeleton
mkdir /tmp/user-skeleton/
ln -s --target-directory /tmp/user-skeleton/\
  "/usr/src/nextcloud/core/skeleton/Nextcloud intro.mp4" \
  "/usr/src/nextcloud/core/skeleton/Readme.md" \
  "/usr/src/nextcloud/core/skeleton/Documents/Nextcloud flyer.pdf" \
  "/usr/src/nextcloud/core/skeleton/Documents/Welcome to Nextcloud Hub.docx" \
  /usr/src/nextcloud/core/skeleton/Templates \
  /usr/src/nextcloud/core/skeleton/Photos/Birdie.jpg \
  /usr/src/nextcloud/core/skeleton/Photos/Frog.jpg \
  /usr/src/nextcloud/core/skeleton/Photos/Vineyard.jpg \

php occ config:system:set skeletondirectory --value /tmp/user-skeleton/
php occ maintenance:repair --include-expensive
php occ db:add-missing-indices

exec php-fpm
