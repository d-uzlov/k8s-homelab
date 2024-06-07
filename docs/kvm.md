
# IP KVM for non-RPi devices

References:
- https://github.com/srepac/kvmd-armbian
- https://psenyukov.ru/pikvm-%D0%B4%D0%BB%D1%8F-%D0%BF%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B8-%D0%BB%D1%8E%D0%B1%D0%BE%D0%B3%D0%BE-%D0%BE%D0%B4%D0%BD%D0%BE%D0%BF%D0%BB%D0%B0%D1%82%D0%BD%D0%BE%D0%B3/

For Orange Pi Zero 2w you need to disable `fix-nfs-msd` in the script.
Also, you may need to replace `gpiod.LineEvent` manually.

# USB relays

USB HID relays can be used to trigger buttons, like the power button of a PC.

Software to use them:
- https://github.com/darrylb123/usbrelay

Version in the Debian repo is old and doesn't support new devices,
so you are better off building it from source.

```bash
git clone https://github.com/darrylb123/usbrelay.git
cd usbrelay

make
sudo make install

sudo usermod -a -G plugdev $USER
sed -e 's/usbrelay/plugdev/' 50-usbrelay.rules | sudo tee /etc/udev/rules.d/50-usbrelay.rules
sudo udevadm control -R
# also reconnect to ssh at this point to apply the new user group

ls -la /dev/hidraw* /dev/usbrelay*

# list available pins
usbrelay
```

Usage example:

```bash
# without args prints all available pins
usbrelay
# PSUIS_1=1
# PSUIS_2=0

# set pin like this
usbrelay PSUIS_1=0

# here id of the relay couldn\t be read, so it's just _1 instead of SOMEPREFIX_1
usbrelay
# _1=0
# _2=0
# _3=0
# _4=0
# _5=0
# _6=0
# _7=0
# _8=0

# you can set pins via this short name
usbrelay _1=0
# you can also use the device path
usbrelay /dev/hidraw0_1=0
usbrelay /dev/usbrelay5-1_1=0
```

# Set up access to USB relay from the UI

Take the content of [kvm.yaml](./kvm.yaml) and place it
into the pikvm system at `/etc/kvmd/override.d/power-relay.yaml`.

Then add device-specific config and reload `kvmd`:

```bash
sudo usermod -a -G plugdev kvmd

# create the script that will actually switch the relay
# you will likely need to change /dev/usbrelay5-1_1 to your own path
sudo mkdir -p /etc/kvmd/scripts/
echo '
#!/bin/bash
set -e
delay=$1
usbrelay -q /dev/usbrelay5-1_1=1
sleep $delay
usbrelay -q /dev/usbrelay5-1_1=0
' | sudo tee /etc/kvmd/scripts/usb-relay-press.sh
sudo chmod +x /etc/kvmd/scripts/*.sh

# restart `kvmd` to pick up new config and the plugdev group
sudo systemctl restart kvmd
sudo systemctl status kvmd
```
