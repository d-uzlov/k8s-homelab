#!/bin/bash
set -eu

umask 0

target_directory=$1

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

user="$(id -u)"
group="$(id -g)"

if [ "$(id -u)" = 0 ]; then
    rsync_options="-rlDog --chown $user:$group"
else
    rsync_options="-rlD"
fi

for dir in config custom_apps themes; do
    if [ ! -d "$target_directory/$dir" ] || directory_empty "$target_directory/$dir"; then
        rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ "$target_directory"
    else
        echo skipping rsync on "$dir": not empty
        ls -lahF "$target_directory/$dir"
    fi
done

echo init-webroot-mutable finished
