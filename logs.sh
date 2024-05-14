#!/usr/bin/env bash

namespace=$1
name=$2

for pod in $(kl -n "$namespace" get pods -o name | grep "${name}"); do
    kl -n "$namespace" logs $pod | sed -e 's|^|'"$pod"'|g'
done
