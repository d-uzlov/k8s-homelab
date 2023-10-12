#!/bin/sh
set -eu

trap : TERM INT

path=$1

if [ -f "$path" ] && echo "$SHA1SUM  $path" | sha1sum -c -; then
  chmod 777 "$path"
  echo file already exists, skipping download
  exit 0
fi

url="https://github.com/aptible/supercronic/releases/download/$VERSION/supercronic-linux-amd64"
curl -fsSL "$url" > "$path" & wait -n
echo "$SHA1SUM  $path" | sha1sum -c -
chmod 777 "$path"
echo success!
