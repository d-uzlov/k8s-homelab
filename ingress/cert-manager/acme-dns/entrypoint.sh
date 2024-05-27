#!/bin/sh
set -eu

tmp_file=/etc/acme-dns/create-config.sh
trap 'rm -f $tmp_file' 0 1 2 3 15;   # Clean up the temporary file 

(
  echo 'cat << END_OF_TEXT'
  cat /etc/acme-dns-config/config.cfg
  echo 'END_OF_TEXT'
) > $tmp_file
. $tmp_file > /etc/acme-dns/config.cfg

exec ./acme-dns
