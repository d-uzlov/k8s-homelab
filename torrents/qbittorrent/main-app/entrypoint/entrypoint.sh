#!/bin/bash
set -eu

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

umask 0
trap : TERM INT

profilePath="$CONFIG_LOCATION"
configFile="$profilePath/qBittorrent/config/qBittorrent.conf"
watchFile="$profilePath/qBittorrent/config/watched_folders.json"
logLocation="$profilePath/log"

"$parent_path"/update_config.sh "$configFile" "$watchFile" "$logLocation"

customConfigPrefix="$profilePath/qBittorrent/config/custom_config"
echo "$FINISHED_FOLDER" > "$customConfigPrefix"-finished

# force bittorrent logs to stdout
# https://github.com/qbittorrent/qBittorrent/issues/10077
echo "redirecting log file to stdout..."
mkdir -p "$logLocation"
log_file="$logLocation/qbittorrent.log"
rm -f "$log_file"
mkfifo "$log_file"
while :; do cat "$log_file"; done &

echo "starting qbittorrent-nox..."
exec qbittorrent-nox \
    --profile="$profilePath" \
    "$@"
