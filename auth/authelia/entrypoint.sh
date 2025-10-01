#!/bin/sh
set -eu

poll_period=2

pid_file=/run/authelia-pid
shutdown_file=/run/shutdown-requested
reload_file=/run/reload-requested

sigterm_handler() {
  echo "$(date) Entrypoint: sigterm_handler: received SIGTERM/SIGINT, forwarding..."
  touch $shutdown_file
  pid="$(cat $pid_file)"
  kill -TERM "$pid" || true
  wait "$pid" || true
  echo "$(date) Entrypoint: sigterm_handler: app finished"
}

trap sigterm_handler TERM INT

print_config_hash() {
  sha1sum /config/* | sha1sum
}

poll_for_config_changes() {
  old_hash=$(print_config_hash)
  while true; do
    sleep $poll_period
    new_hash=$(print_config_hash)
    if [ "$old_hash" != "$new_hash" ]; then
      echo "$(date) Entrypoint: poll loop: checksum change detected, restarting app"
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
  echo "$(date) Entrypoint: run loop: starting application"
  authelia &
  pid=$!
  echo $pid > $pid_file
  wait $pid || {
    exit_code=$?
    true
  }
  if [ -f "$shutdown_file" ]; then
    echo "$(date) Entrypoint: run loop: exiting: detected shutdown"
    exit 0
  elif [ -f "$reload_file" ]; then
    echo "$(date) Entrypoint: run loop: detected reload"
    rm $reload_file
  else
    echo "$(date) Entrypoint: run loop: exiting: application finished with exit_code $exit_code"
    exit $exit_code
  fi
done
