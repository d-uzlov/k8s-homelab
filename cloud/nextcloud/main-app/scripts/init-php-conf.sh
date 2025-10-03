#!/bin/sh
set -eu

echo copy php config to mounted dir...
cp /usr/local/etc/php/conf.d/* "$PHP_CONF_D_LOCATION"
echo create redis-session.ini
cat << EOF > "$PHP_CONF_D_LOCATION"/redis-session.ini
session.save_handler = redis
session.save_path = "tcp://$REDIS_HOST:6379?auth=$REDIS_PASSWORD"
redis.session.locking_enabled = 1
redis.session.lock_retries = -1
redis.session.lock_wait_time = 10000
EOF
