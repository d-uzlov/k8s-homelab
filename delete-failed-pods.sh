#!/bin/bash

kl delete pods --field-selector status.phase=Failed --all-namespaces &
p1=$!
kl delete pods --field-selector status.phase=Succeeded --all-namespaces &
p2=$!

wait $p1 $p2
