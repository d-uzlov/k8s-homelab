#!/bin/sh
set -eu

install_flag_file=/var/www/html/version.php
if [ ! -f "$install_flag_file" ]; then
  echo "$install_flag_file does not exist, make sure that nextcloud is installed"
  exit 1
fi

chmod +rw -R /var/www/html/config/* || true

# make sure that cron doesn't run while nc is being installed or upgraded
#   See if this has been fixed: https://github.com/nextcloud/server/issues/28508
#   don't wait, just skip
#   - initial install doesn't need cron too much, it can wait 5 minutes
#   - upgrade should run cron manually
#   - this should also help if you run several instances of cron deployment
flock --nonblock /var/nextcloud/shared-lock/nextcloud-init-sync.lock php -f /var/www/html/cron.php || {
  echo sync file is already locked
  exit 1
}
