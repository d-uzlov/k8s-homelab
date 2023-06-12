#!/bin/bash

set -eu

hash="$1"
savepath="$2"

function run_curl() {
    api="$1"
    check_result="$2"
    error_prefix="$3"
    data="$4"
    retcode=0
    result=$(curl --silent --fail-with-body --noproxy localhost --request POST "http://localhost:${WEBUI_PORT}$api" --data "$data") || retcode=$?
    [ "$check_result" = "false" ] || ([ -z "$result" ] && [ $retcode = 0 ]) || echo "$error_prefix: \$?=$retcode: $result"
}

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
[ -z "$category" ] || run_curl '/api/v2/torrents/createCategory' false "$error_prefix" "category=$category&savePath=$FINISHED_FOLDER/$category"
[ -z "$category" ] || run_curl '/api/v2/torrents/setCategory'    true  "$error_prefix" "hashes=$hash&category=$category"
[ -z "$tags" ]     || run_curl '/api/v2/torrents/addTags'        true  "$error_prefix" "hashes=$hash&tags=$tags"
