#!/bin/bash

# Increase to 360 hours (1296000 seconds):
#   https://tomschlick.com/blog/2022/06/28/extend-truenas-web-ui-session-timeout/
#   https://www.reddit.com/r/truenas/comments/vn1tu7/extend_truenas_web_ui_session_timeout/
if [ "$(uname)" = "Linux" ]; then
  sed -i 's/auth.generate_token",\[300/auth.generate_token",\[1296000/g' /usr/share/truenas/webui/*.js || exit
elif [ "$(uname)" = "FreeBSD" ]; then
  sed -i '' 's/auth.generate_token",\[300/auth.generate_token",\[1296000/g' /usr/local/www/webui/*.js || exit
fi

midclt call system.advanced.update '{"motd": ""}' || exit

# Disable stupid swap on data drives
midclt call system.advanced.update '{"swapondrive": 0}' || exit

cli -c "service smart config"
cli -c "service smart update powermode=STANDBY"

cli -c "system system_dataset update pool=boot-pool"
midclt call system.system_dataset.update '{"pool": "boot-pool"}' || exit || exit

zfs set atime=off boot-pool || exit
zfs set relatime=off boot-pool || exit

####################

function list_smart_drives() (
  for drive in $(smartctl --scan | grep "dev" | awk '{print $1}'); do
    smartctl -i "$drive" | grep "SMART support is: Enabled" > /dev/null && echo "${drive}"
  done
)

function set_erc() (
  echo "Configuring drive: $1"
  readsetting=70
  writesetting=70
  smartctl -q silent -l scterc,"${readsetting}","${writesetting}" "$1"
  smartctl -l scterc "$1" | grep "SCT\|Write\|Read"
)

( for drive in $(list_smart_drives); do
set_erc "$drive";
done; )

####################
