#!/bin/bash

trap : TERM INT

saveLocation=/home/nitrox/.config/Nitrox/saves/docker-save
config=$saveLocation/server.cfg

function setupConfig() {
  file=$1
  sed -i \
    -e "s/SaveName=.*/SaveName=docker-save/" \
    -e "s/Seed=SEED_AUTOREPLACE/Seed=$SEED/" \
    -e "s/AdminPassword=.*/AdminPassword=$ADMIN_PASSWORD/" \
    -e "s/ServerPassword=.*/ServerPassword=$SERVER_PASSWORD/" \
    -e "s/GameMode=.*/GameMode=$GAME_MODE/" \
    -e "s/CreateFullEntityCache=.*/CreateFullEntityCache=$ENABLE_STARTUP_CACHE/" \
    $file
}
if [ ! -f $config ]; then
  cp /mnt/config-template/server-template.cfg $config
fi

setupConfig $config

echo "Starting the Nitrox server..."
cd /nitrox
mono /nitrox/NitroxServer-Subnautica.exe /home/nitrox/.config/Nitrox/saves/docker-save &
wait
