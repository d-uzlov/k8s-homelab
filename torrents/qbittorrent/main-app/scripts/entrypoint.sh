#!/bin/bash
set -eu

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

umask 0
trap : TERM INT

profilePath="$CONFIG_LOCATION"
configFile="$profilePath/qBittorrent/config/qBittorrent.conf"
watchFile="$profilePath/qBittorrent/config/watched_folders.json"
logLocation="$profilePath/log"

# =========== Update config ===========
"$parent_path"/update_config.sh "$configFile" "$watchFile" "$logLocation"

# =========== Update fastresume files ===========
customConfigPrefix="$profilePath/qBittorrent/config/custom_config"
fastresumePath="$profilePath/qBittorrent/data/BT_backup"

oldIncompletePath=$(cat "$customConfigPrefix"-incomplete) || true
oldFinishedPath=$(cat "$customConfigPrefix"-finished) || true
if [ ! -z "$oldIncompletePath" ] && [ ! -z "$oldFinishedPath" ]; then
    if [ ! "$oldIncompletePath" = "$INCOMPLETE_FOLDER" ] || [ ! "$oldFinishedPath" = "$FINISHED_FOLDER" ]; then
        echo updating .fastresume files...
        python3 "$parent_path"/update_fastresume.py \
            --value 16:qBt-downloadPath "$oldIncompletePath" "$INCOMPLETE_FOLDER" \
            --value 12:qBt-savePath     "$oldFinishedPath"   "$FINISHED_FOLDER" \
            --value 9:save_path         "$oldFinishedPath"   "$FINISHED_FOLDER" \
            --directory "$fastresumePath"
        echo updating .fastresume files done
    fi
fi
echo -n "$INCOMPLETE_FOLDER" > "$customConfigPrefix"-incomplete
echo -n "$FINISHED_FOLDER" > "$customConfigPrefix"-finished

# =========== Force logs to stdout ===========
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
