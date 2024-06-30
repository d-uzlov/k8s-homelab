#!/bin/bash
set -eu

real_version_file=$1

ls -la /var/www/html

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p "$user" -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

# Execute all executable files in a given directory in alphanumeric order
run_path() {
    local hook_folder_path="/docker-entrypoint-hooks.d/$1"
    local return_code=0

    echo "=> Searching for scripts (*.sh) to run, located in the folder: ${hook_folder_path}"

    if [ -z "$(ls -A "${hook_folder_path}")" ]; then
      echo "==> but the hook folder \"$(basename "${hook_folder_path}")\" is empty, so nothing to do"
        return 0
    fi

    (
        for script_file_path in "${hook_folder_path}/"*.sh; do
            if ! [ -x "${script_file_path}" ] && [ -f "${script_file_path}" ]; then
                echo "==> The script \"${script_file_path}\" in the folder \"${hook_folder_path}\" was skipping, because it didn't have the executable flag"
                continue
            fi

            echo "==> Running the script (cwd: $(pwd)): \"${script_file_path}\""

            run_as "${script_file_path}" || return_code="$?"

            if [ "${return_code}" -ne "0" ]; then
                echo "==> Failed at executing \"${script_file_path}\". Exit code: ${return_code}"
                exit 1
            fi

            echo "==> Finished the script: \"${script_file_path}\""
        done
    )
}

user="$(id -u)"
group="$(id -g)"

installed_version="0.0.0.0"
if [ -f "$real_version_file" ]; then
    installed_version="$(php -r "require \"$real_version_file\""'; echo implode(".", $OC_Version);')"
fi
image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
    exit 1
fi

# Install
if [ "$installed_version" = "0.0.0.0" ]; then
    echo "New nextcloud instance"
    echo "Initializing nextcloud $image_version ..."

    # shellcheck disable=SC2016
    install_options="-n --admin-user '"$NEXTCLOUD_ADMIN_USER"' --admin-pass '"$NEXTCLOUD_ADMIN_PASSWORD"'"
    install_options="$install_options --data-dir '"$NEXTCLOUD_DATA_DIR"'"

    if [ "$DB_TYPE" = "mysql" ]; then
        echo "Installing with MySQL database"
        install_options="$install_options --database mysql --database-name '"$MYSQL_DATABASE"' --database-user '"$MYSQL_USER"' --database-pass '"$MYSQL_PASSWORD"' --database-host '"$MYSQL_HOST"'"
    elif [ "$DB_TYPE" = "postgres" ]; then
        echo "Installing with PostgreSQL database"
        install_options="$install_options --database pgsql --database-name '"$POSTGRES_DB"' --database-user '"$POSTGRES_USER"' --database-pass '"$POSTGRES_PASSWORD"' --database-host '"$POSTGRES_HOST"'"
    fi

    run_path pre-installation

    echo "Starting nextcloud installation"
    max_retries=10
    try=0
    until run_as "php /var/www/html/occ maintenance:install $install_options" || [ "$try" -gt "$max_retries" ]
    do
        echo "Retrying install..."
        try=$((try+1))
        sleep 10s
    done
    if [ "$try" -gt "$max_retries" ]; then
        echo "Installing of nextcloud failed!"
        exit 1
    fi
    cp /usr/src/nextcloud/version.php "$real_version_file"

    run_path post-installation

    installed_version=$image_version
fi

# upgrade
if version_greater "$image_version" "$installed_version"; then
    if [ "${image_version%%.*}" -gt "$((${installed_version%%.*} + 1))" ]; then
        echo "Can't start Nextcloud because upgrading from $installed_version to $image_version is not supported."
        echo "It is only possible to upgrade one major version at a time. For example, if you want to upgrade from version 14 to 16, you will have to upgrade from version 14 to 15, then from 15 to 16."
        exit 1
    fi
    echo "Upgrading nextcloud from $installed_version ..."
    list_before=$(run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p")

    run_path pre-upgrade

    run_as 'php /var/www/html/occ upgrade'
    rm "$real_version_file"
    cp /usr/src/nextcloud/version.php "$real_version_file"

    list_after=$(run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p")
    echo "The following apps have been disabled:"
    diff <(echo $list_before) <(echo $list_after) | grep '<' | cut -d- -f2 | cut -d: -f1 | tee "/var/www/html/config/apps-disabled-for-$image_version.log"

    run_path post-upgrade

    echo run cron job to renew caches...
    php -f /var/www/html/cron.php

    echo "Initializing finished"
fi

run_path before-starting

echo install finished
