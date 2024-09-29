#!/usr/bin/env bash

if [ -z "$1" ]; then
cat << EOF
Usage:
$0 namespace name-prefix

Print logs from all pods in this namespace that have names start with specified prefix.
Prepend pod name to each line.
EOF
exit
fi

namespace=$1
name=$2

for pod in $(kl -n "$namespace" get pods -o name | grep "^pod/${name}"); do
    kl -n "$namespace" logs $pod | sed -e 's|^|'"$pod"': |'
done
