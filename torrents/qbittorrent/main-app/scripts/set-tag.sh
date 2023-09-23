#!/bin/bash

set -eu
set -o pipefail

hash=$1

qbt_api_host=${QBT_API_HOST:-}
if [ -z "$qbt_api_host" ]; then
  qbt_api_host=http://localhost:${WEBUI_PORT}
fi

function run_curl() {
  api=$1
  data=$2
  curl --silent --fail-with-body --noproxy localhost --request POST "$qbt_api_host$api" --data "$data"
}

function get_torrent_info() {
  api=$1
  prop_name=$2
  hash=$3
  run_curl "$api" "hash=$hash" | sed -e 's/.*"'"$prop_name"'":"\([^"]*\)".*/\1/'
}

function curl_set() {
  api=$1
  check_result=$2
  error_prefix=$3
  data=$4

  retcode=0
  result=$(run_curl "$api" "$data") || retcode=$?
  if [ "$check_result" = 'true' ] && ([ ! -z "$result" ] || [ ! $retcode = 0 ]); then
      echo "error: $error_prefix: \$?=$retcode: $result"
      return $retcode
  fi
}

savepath=$(get_torrent_info /api/v2/torrents/properties save_path "$hash")

[[ "$savepath" == "$FINISHED_FOLDER"* ]] || exit

relativePath=${savepath#$FINISHED_FOLDER}
relativePath=${relativePath#/}

tags=
category=

if [ ! -z "$relativePath" ]; then
  category=$(cut -d/ -f1 <<< "$relativePath")
  if [ ! "$relativePath" = "$category" ]; then
    tags="path:$relativePath"
  fi
fi

## auth is not required because we enable auth bypass for localhost
# curl --silent --fail --show-error \
#     --cookie-jar /tmp/webapi-cookie.txt \
#     --data "username=admin&password=adminadmin" \
#     --request POST \
#     "http://localhost:8080/api/v2/auth/login"

error_prefix="$hash: $savepath"
[ -z "$category" ] || curl_set /api/v2/torrents/createCategory false "$error_prefix"             "category=$category&savePath=$FINISHED_FOLDER/$category"
[ -z "$category" ] || curl_set /api/v2/torrents/setCategory    true  "setCategory $error_prefix" "hashes=$hash&category=$category"
[ -z "$tags" ]     || curl_set /api/v2/torrents/addTags        true  "addTags $error_prefix"     "hashes=$hash&tags=$tags"
