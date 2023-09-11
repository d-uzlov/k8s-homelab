#!/bin/bash
set -eu

umask 0
trap : TERM INT

function set_value() {
    config="$1"
    name="$2"
    value="$3"

    # escape \
    name="${name//'\'/'\\'}"
    value="${value//'\'/'\\'}"
    # escape /
    name="${name//'/'/'\/'}"
    value="${value//'/'/'\/'}"
    # escape ~
    name="${name//'~'/'\~'}"
    value="${value//'~'/'\~'}"

    echo "set $name to $value"

    sed -i "s~^\($name\s*=\s*\).*\$~\1$value~" "$config"
}

function checkEnv() {
    name=$1
    allowedValues=${2:-}

    if [ -z "${!name+x}" ]; then
        echo "error: required env is empty: $name"
        exit 1
    fi
    echo "$name == ${!name}"
    
    if [ ! -z "$allowedValues" ]; then
        echo "allowed values are: $allowedValues"
    fi
}

checkEnv WEBUI_PORT
checkEnv DATA_PORT
checkEnv DEFAULT_CONFIG_LOCATION
checkEnv CONFIG_LOCATION
checkEnv FORCE_OVERWRITE_CONFIG "true false"
checkEnv RESET_PASSWORD "true false"
checkEnv ENABLE_TMP_FOLDER "true false"
checkEnv TRUSTED_PROXIES "comma-separated CIDR list, or empty"
checkEnv AUTH_WHITELIST "comma-separated CIDR list, or empty"
checkEnv WATCH_ROOT "path to the root of the watch folder"
checkEnv ADDED_HOOK_SCRIPT "path to script file that runs when a new torrent is added, or empty"
checkEnv INCOMPLETE_FOLDER "path to the folder for incomplete torrents"
checkEnv FINISHED_FOLDER "path to the folder for finished torrents"

useAuthWhitelist=
if [ ! -z "$AUTH_WHITELIST" ]; then
    useAuthWhitelist='true'
else
    useAuthWhitelist='false'
fi
useTrustedProxies=
if [ ! -z "$TRUSTED_PROXIES" ]; then
    useTrustedProxies='true'
else
    useTrustedProxies='false'
fi

profilePath="$CONFIG_LOCATION"
configFile="$profilePath/qBittorrent/config/qBittorrent.conf"
watchFile="$profilePath/qBittorrent/config/watched_folders.json"
logLocation="$profilePath/log"

isNewConfig=false
if [ "$FORCE_OVERWRITE_CONFIG" = "true" ] || [ ! -f "$configFile" ]; then
    isNewConfig=true
    echo "copying/overwriting main config file..."
    rm -rf "$configFile"
    mkdir -p "$(dirname "$configFile")"
    cp -f "$DEFAULT_CONFIG_LOCATION/qBittorrent.conf" "$configFile"
fi

if [ "$FORCE_OVERWRITE_CONFIG" = "true" ] || [ ! -f "$watchFile" ]; then
    echo "copying/overwriting watched folders file..."
    rm -rf "$watchFile"
    mkdir -p "$(dirname "$watchFile")"
    cp -f "$DEFAULT_CONFIG_LOCATION/watched_folders.json" "$watchFile"
    sed -i "s|AUTOMATIC_REPLACE_WATCH_ROOT|$WATCH_ROOT|" "$watchFile"
    sed -i "s|AUTOMATIC_REPLACE_INCOMPLETE_FOLDER|$INCOMPLETE_FOLDER|" "$watchFile"
    sed -i "s|AUTOMATIC_REPLACE_FINISHED_FOLDER|$FINISHED_FOLDER|" "$watchFile"
fi

# without this this script can fail because
# config file deletion is registered but config copy isn't yet
# BTW WTF is wrong with NFS? Why can't client see the file that it has just created?
sleep 0.5

echo "changing important settings..."
set_value "$configFile" 'Accepted' "true"
set_value "$configFile" 'Session\Port' "$DATA_PORT"
set_value "$configFile" 'Session\DefaultSavePath' "$FINISHED_FOLDER"
set_value "$configFile" 'FileLogger\Enabled' "true"
set_value "$configFile" 'FileLogger\DeleteOld' "false"
set_value "$configFile" 'FileLogger\Path' "$logLocation"
set_value "$configFile" 'PortForwardingEnabled' "false"
set_value "$configFile" 'WebUI\Port' "$WEBUI_PORT"
set_value "$configFile" 'WebUI\ReverseProxySupportEnabled' "$useTrustedProxies"
set_value "$configFile" 'WebUI\TrustedReverseProxiesList' "$TRUSTED_PROXIES"
set_value "$configFile" 'WebUI\AuthSubnetWhitelistEnabled' "$useAuthWhitelist"
set_value "$configFile" 'WebUI\AuthSubnetWhitelist' "$AUTH_WHITELIST"
set_value "$configFile" 'WebUI\UseUPnP' "false"

if [ "$ENABLE_TMP_FOLDER" = 'true' ] && [ ! -z "$INCOMPLETE_FOLDER" ] && [ ! "$INCOMPLETE_FOLDER" = "$FINISHED_FOLDER" ]; then
    set_value "$configFile" 'Session\TempPathEnabled' "true"
else
    set_value "$configFile" 'Session\TempPathEnabled' "false"
fi
set_value "$configFile" 'Session\TempPath' "$INCOMPLETE_FOLDER"

if [ ! -z "$ADDED_HOOK_SCRIPT" ]; then
    set_value "$configFile" 'OnTorrentAdded\Program' "$ADDED_HOOK_SCRIPT "'\"%I\" \"%D\"'
else
    set_value "$configFile" 'OnTorrentAdded\Program' ''
fi

if [ "$RESET_PASSWORD" = "true" ] || [ "$isNewConfig" = 'true' ]; then
    echo "resetting password..."
    userValue=${USERNAME:-admin}
    set_value "$configFile" 'WebUI\Username' "$userValue"
    # encoded value for adminadmin
    defaultPass='"@ByteArray(mF/Yn6wBmEW81W2xuMnlbw==:Z0N2dnsPfcgKP/57vZTFPyKr7nYRaxj2jON+4wrWH/ClVp7J3Xd6tz9Sje/oCqu/Y4+i/MmWrvqg/zVfZ6cQuA==)"'
    passValue=${PASSWORD_PBKDF2:-$defaultPass}
    set_value "$configFile" 'WebUI\Password_PBKDF2' "$passValue"
fi

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
