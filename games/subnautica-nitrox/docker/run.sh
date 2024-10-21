#!/bin/bash

trap : TERM INT

if [ ! -d "/subnautica/Subnautica_Data" ]; then
	echo "Game files could not be found"
	echo "You need to mount game directory at /subnautica inside the container"
	exit 1
fi

echo "Starting the Nitrox server..."
cd /nitrox
mono /nitrox/NitroxServer-Subnautica.exe "$@" &
wait
