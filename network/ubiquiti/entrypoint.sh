#!/bin/bash
set -eu

trap : TERM INT

umask 0

# sleep infinity & wait

exec java -Xms"1024M" -Xmx"1024M" -Dlog4j2.formatMsgNoLookups=true -jar /usr/lib/unifi/lib/ace.jar start
