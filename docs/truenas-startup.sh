#!/bin/bash

midclt call system.advanced.update '{"motd": ""}'

# Disable stupid swap on data drives
midclt call system.advanced.update '{"swapondrive": 0}'

# cli -c "service smart config"
cli -c "service smart update powermode=STANDBY"

# cli -c "system system_dataset update pool=boot-pool"
# midclt call system.system_dataset.update '{"pool": "boot-pool"}'

zfs set atime=off boot-pool
zfs set relatime=off boot-pool

####################

function list_smart_drives() (
  for drive in $(smartctl --scan | grep "dev" | awk '{print $1}'); do
    smartctl -i "$drive" | grep "SMART support is: Enabled" > /dev/null && echo "${drive}"
  done
)

function set_erc() (
  echo "Configuring drive: $1"
  readsetting=70
  writesetting=70
  smartctl -q silent -l scterc,"${readsetting}","${writesetting}" "$1"
  smartctl -l scterc "$1" | grep "SCT\|Write\|Read"
)

# enable ERC for all drives that support it
for drive in $(list_smart_drives); do
  ( set_erc "$drive" )
done

####################

echo "Enable DHCP for all network interfaces..."
for netint in $(ls /sys/class/net); do
  if [ "$netint" = "lo" ]; then continue; fi
  echo "enabling DHCP for $netint"
  sudo dhclient "$netint"
done
echo "Done with DHCP."
