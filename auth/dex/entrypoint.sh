#!/bin/sh
set -eu

# Path to watch (file or directory)
config_path=/etc/dex/config.yaml
poll_period=2

pid_file=/run/dex-pid
shutdown_file=/run/shutdown-requested
reload_file=/run/reload-requested

sigterm_handler() {
  echo "Entrypoint: received SIGTERM/SIGINT, forwarding..."
  touch $shutdown_file
  pid="$(cat $pid_file)"
  kill -TERM "$pid" || true
  wait "$pid" || true
  echo Entrypoint: app finished
}

trap sigterm_handler TERM INT

poll_for_config_changes() {
  old_hash=$(sha1sum $config_path)
  while true; do
    sleep $poll_period
    new_hash=$(sha1sum $config_path)
    if [ "$old_hash" != "$new_hash" ]; then
      echo "Entrypoint: checksum change detected, restarting app"
      old_hash="$new_hash"
      pid="$(cat $pid_file)"
      touch $reload_file
      kill -TERM "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
}

poll_for_config_changes &

while [ ! -f "$shutdown_file" ]; do
  dex serve --web-http-addr=0.0.0.0:5556 --telemetry-addr=0.0.0.0:5558 $config_path &
  pid=$!
  echo $pid > $pid_file
  wait $pid || {
    exit_code=$?
    # when dex receives termination signal it exits with an error,
    # so we need to have special handling for reload requests
    if [ -f "$reload_file" ]; then
      echo Entrypoint: detected reload
      rm $reload_file
    elif [ -f "$shutdown_file" ]; then
      echo Entrypoint: detected shutdown, exiting
      exit 0
    else
      echo Entrypoint: application failed, exiting
      exit $exit_code
    fi
  }
done
