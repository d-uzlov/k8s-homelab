#!/bin/bash

resource=$1
[ ! "$resource" = "" ] || { echo "you need to specify type of resource you need to be deleted"; exit 1; }

namespaces=$(kl get ns -o jsonpath='{.items..metadata.name}')

for namespace in $namespaces; do
    kl -n $namespace delete $resource --all
done
