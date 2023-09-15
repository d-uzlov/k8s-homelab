#!/bin/sh
set -eu

umask 0

echo "Changing config dir permissions..."
chmod +rw -R /var/www/html/config/* || true

exec "$@"
