#!/bin/sh
set -eu

umask 0

# this script runs before installation
# so the only way to configure the application is to use config files
echo creating datadir_permissions.config.php...
cat << EOF > /var/www/html/config/datadir_permissions.config.php
<?php
\$CONFIG = array (
    'check_data_directory_permissions' => false
);
EOF
echo creating umask.config.php...
cat << EOF > /var/www/html/config/umask.config.php
<?php
\$CONFIG = array (
    'localstorage.umask' => 0,
);
EOF
