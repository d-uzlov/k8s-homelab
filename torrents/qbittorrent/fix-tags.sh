#!/bin/bash

set -eu
set -o pipefail

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

url=$1
finished_folder=$2

function run_curl() {
  api=$1
  data=$2
  curl --silent --fail-with-body --request POST "https://$url$api" --data "$data"
}

hash_list=$(run_curl /api/v2/torrents/info '' | jq --raw-output '.[] | .hash')
for hash in $hash_list
do
  echo "fixing $hash"
  QBT_API_HOST="https://$url" FINISHED_FOLDER="$finished_folder" "$parent_path"/main-app/scripts/set-tag.sh "$hash"
done
