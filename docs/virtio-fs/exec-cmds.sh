#!/bin/bash

VMID="$1"
ACTION="$2"
SLEPT=""

vmpid() {
  cat "/var/run/qemu-server/$VMID.pid"
}

if_action() {
  if [[ "$ACTION" == "$1" ]]; then
    shift
    eval "$@"
  fi
}

sleep_once() {
  if [[ -z "$SLEPT" ]]; then
    sleep 1s
    SLEPT=1
  fi
}

exec_virtiofsd() {
  echo "Needs virtiofsd for directory $1"
  /usr/lib/kvm/virtiofsd --socket-path=/run/qemu-server/$VMID-${1/\//}.virtiofsd -o source=$1 -o cache=always --daemonize > /dev/null 2>&1 &
}

exec_cmds() {
  while read CMD ARG1 ARG2 REST; do
    case "$CMD" in
      "#virtiofsd")
        if_action pre-start exec_virtiofsd "$ARG1"
        ;;

    esac
  done
}

exec_cmds < "/etc/pve/qemu-server/$1.conf"

exit 0
