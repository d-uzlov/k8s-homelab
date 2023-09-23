#!/bin/bash

kl delete pods --field-selector status.phase=Failed --all-namespaces &
kl delete pods --field-selector status.phase=Succeeded --all-namespaces &
