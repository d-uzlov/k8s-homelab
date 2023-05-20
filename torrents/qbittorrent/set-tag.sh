#!/bin/bash

set -eu

savepath="$1"
hash="$2"
host="http://localhost:8080"

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

function run_curl() {
    api="$1"
    check_result="$2"
    data="$3"
    result=$(curl --silent --fail-with-body --noproxy localhost --request POST 'localhost:8080'"$api" --data "$data")
    retcode=$?
    [ "$check_result" = "false" ] || [ -z "$result" ] || echo "$hash: $savepath: $retcode: $result"
}

## auth is not required because we enable auth bypass for localhost
# curl --silent --fail --show-error \
#     --cookie-jar /tmp/webapi-cookie.txt \
#     --data "username=admin&password=adminadmin" \
#     --request POST \
#     "http://localhost:8080/api/v2/auth/login"

[ -z "$category" ] || run_curl '/api/v2/torrents/createCategory' false "category=$category&savePath=$FINISHED_FOLDER/$category"
[ -z "$category" ] || run_curl '/api/v2/torrents/setCategory'    true  "hashes=$hash&category=$category"
[ -z "$tags" ]     || run_curl '/api/v2/torrents/addTags'        true  "hashes=$hash&tags=$tags"
