#!/bin/bash

if [ -z "$1" ]; then
cat << EOF
Usage:
$0 resource_name

Go over all namespaces and delete --all resource_name
EOF
exit
fi

resource=$1

namespaces=$(kl get ns -o jsonpath='{.items..metadata.name}')

for namespace in $namespaces; do
    kl -n $namespace delete $resource --all
done
