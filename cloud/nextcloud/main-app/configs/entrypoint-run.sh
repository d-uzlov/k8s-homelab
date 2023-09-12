#!/bin/sh
set -eu

# umask 0006
umask 0

exec "$@"
