#!/bin/sh
set -eu

. <(
  echo 'cat << END_OF_TEXT'
  cat /etc/acme-dns-config/config.cfg
  echo 'END_OF_TEXT'
) > /etc/acme-dns/config.cfg

exec ./acme-dns
