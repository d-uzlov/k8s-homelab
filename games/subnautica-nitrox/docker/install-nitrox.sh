#!/bin/bash

set -e

groupadd --gid 1001 nitrox
useradd --gid 1001 --uid 1001 --create-home nitrox

echo "Downloading latest Nitrox release..."
# downloadUrl="https://github.com/SubnauticaNitrox/Nitrox/releases/download/${NITROX_VERSION}/Nitrox_${NITROX_VERSION}.zip"
file=Nitrox-dc90f19-fix-14
downloadUrl="https://github.com/d-uzlov/Nitrox/releases/download/dc90f19/$file.zip"
wget "$downloadUrl" --output-document /tmp/nitrox.zip

echo "Unzipping Nitrox..."
unzip -u /tmp/nitrox.zip -d /tmp/nitrox/
mv /tmp/nitrox/$file/ /nitrox/

echo "Fixing Nitrox permissions..."
chmod +x /nitrox/*.exe

echo "Fixing Nitrox case sensitive filenames..."
ln --symbolic --force /subnautica/Subnautica_Data/Managed/LitJson.dll /nitrox/LitJSON.dll
