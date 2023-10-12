#!/bin/sh
set -eu

trap : TERM INT

umask 0

# -------------------

echo "DB maintenance..."
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#add-missing-indices
echo "Add missing indices..."
php occ db:add-missing-indices
