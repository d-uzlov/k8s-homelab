
# IP KVM for non-RPi devices

References:
- https://github.com/srepac/kvmd-armbian
- Alternative? https://github.com/jacobbar/fruity-pikvm/tree/main
- https://psenyukov.ru/pikvm-%D0%B4%D0%BB%D1%8F-%D0%BF%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B8-%D0%BB%D1%8E%D0%B1%D0%BE%D0%B3%D0%BE-%D0%BE%D0%B4%D0%BD%D0%BE%D0%BF%D0%BB%D0%B0%D1%82%D0%BD%D0%BE%D0%B3/

Installation was tested on Orange Pi Zero 2w and Orange Pi Zero 3 with Debian 12 on 6.1.31 kernel.

For Orange Pi Zero 2w I had to disable `fix-nfs-msd` in the script
and manually replace `gpiod.LineEvent` in python code.
Later for Orange Pi Zero 3 I didn't need to do anything,
so maybe it got patched in the repo.

```bash
sudo apt update && sudo apt full-upgrade -y

sudo apt install -y git make python3-dev gcc xz-utils wget
git clone https://github.com/srepac/kvmd-armbian.git --depth 1
# this will take several minutes
( cd kvmd-armbian && sudo ./install.sh )
# at the end of the script press ENTER when prompted
# the system will reboot

# run install once again after reboot
( cd kvmd-armbian && sudo ./install.sh )
# it will run `kvmd -m` which should spit out a bunch of yaml configs
# enter 'y' if it did
# read errors and fix them if there were errors instead of yaml

curl --insecure https://localhost/login/

# optionally, set up users
# set password for username, create user if needed
sudo kvmd-htpasswd set username
# delete user
sudo kvmd-htpasswd del username
# enable 2FA auth
# the secret is the same for all users
sudo kvmd-totp init
# print secret QR code
sudo kvmd-totp show
# reboot is required for kvmd to pick up 2fa settings
sudo reboot
```

Default credentials are:
- Username: `admin`
- Password: `admin`

# Configuration

References:
- https://docs.pikvm.org/first_steps/#configuring-pikvm

```bash
sudo rm /etc/kvmd/override.yaml
# override.yaml must exist
sudo touch /etc/kvmd/override.yaml

sudo tee << EOF /etc/kvmd/override.d/0-disable-atx-gpio.yaml
# kvmd expects to be running on a raspberry pi,
# and have access to its gpio to use for ATX power/reset/led front panel pins.
# kvmd fails to start when running on other hardware unless you disable atx controls
kvmd:
  atx:
    type: disabled
EOF
sudo tee << EOF /etc/kvmd/override.d/0-disable-msd.yaml
kvmd:
  msd:
    type: disabled
EOF
# relative mouse is only needed in case your OS
# does not suport absolute mouse mode
# source: https://docs.pikvm.org/mouse/
# sudo tee << EOF /etc/kvmd/override.d/0-enable-relative-mouse.yaml
# kvmd:
#   hid:
#     mouse_alt:
#       device: /dev/kvmd-hid-mouse-alt  # allow relative mouse mode
# EOF
sudo tee << EOF /etc/kvmd/override.d/0-resolution.yaml
kvmd:
  streamer:
    resolution:
      default: 1920x1080
      available:
      - 1920x1080
      - 1600x1200
      - 1280x720
      - 1024x768
      - 800x600
    desired_fps:
      default: 30
EOF

sudo systemctl restart kvmd
sudo systemctl status kvmd
sudo journalctl -u kvmd.service -b
```

# Drive mounts / MSD

This enables you to mount ISOs via emulated CD-ROM or Flash drive.
You may need to disconnect storage USB device to properly switch between CD-ROM and Flash.

```bash
chmod +x ./kvmd-armbian/create-flash-msd.sh ./kvmd-armbian/apply-msd-patch.sh
sudo mkdir /kvmd-storage/
# this creates a 16 GB file that will be mounted as storage partition
# total size of ISO and IMG files will be limited by this partition size
sudo ./kvmd-armbian/create-flash-msd.sh -n image -s 16 -d /kvmd-storage

sudo tee << EOF /etc/kvmd/override.d/1-enable-msd.yaml
kvmd:
  msd:
    type: otg
EOF
# it seems like kvmd updates the list of required kernel modules only on reboot
sudo reboot now

# ¿ optional ?
sudo ./kvmd-armbian/apply-msd-patch.sh -f
```

# Writable Flash drive

You can mount any `.img` file as a writable flash device.
Here we create a small empty image.

Note, that if you want to get files from this image,
you will have to download the whole image,
so you probably want to keep it small.

```bash
sudo kvmd-helper-otgmsd-remount rw
# in megabytes
size=512
sudo dd if=/dev/zero of=/var/lib/kvmd/msd/flash.img bs=1M count=$size status=progress
sudo chmod 666 /var/lib/kvmd/msd/flash.img
sudo kvmd-helper-otgmsd-remount ro
```

# Device switches

This adds switches in the GPIO section that allow you
to forcefully disconnect emulated USB devices.

```bash
# kvmd-otgconf --make-gpio-config
# make sure that all your devices from kvmd-otgconf are listed here
 sudo tee << EOF /etc/kvmd/override.d/0-usb-conf-gpio.yaml
kvmd:
  gpio:
    drivers:
      otgconf:
        type: otgconf
    scheme:
      hid.usb0:
        driver: otgconf
        mode: output
        pin: hid.usb0
        pulse: false
      hid.usb1:
        driver: otgconf
        mode: output
        pin: hid.usb1
        pulse: false
      hid.usb2:
        driver: otgconf
        mode: output
        pin: hid.usb2
        pulse: false
      mass_storage.usb0:
        driver: otgconf
        mode: output
        pin: mass_storage.usb0
        pulse: false
EOF
 [ -f /etc/kvmd/override.d/99-gpio-view.yaml ] || sudo tee << EOF /etc/kvmd/override.d/99-gpio-view.yaml
kvmd:
  gpio:
    view:
      table:
EOF
# run `kvmd-otgconf --make-gpio-config` to make sure your mapping is correct
 grep "# usb-conf" /etc/kvmd/override.d/99-gpio-view.yaml || sudo tee -a << EOF /etc/kvmd/override.d/99-gpio-view.yaml
      # usb-conf
      - []
      - ["#Keyboard", hid.usb0]
      - ["#Absolute Mouse", hid.usb1]
      #- ["#Relative Mouse", hid.usb2]
      - ["#Mass Storage Drive", mass_storage.usb0]
EOF

sudo systemctl restart kvmd
sudo systemctl status kvmd
```

# USB relays

USB HID relays can be used to trigger buttons, like the power button of a PC.

Software to use them:
- https://github.com/darrylb123/usbrelay

Version in the Debian repo is old and doesn't support new devices,
so you are better off building it from source.

```bash
git clone https://github.com/darrylb123/usbrelay.git --depth 1
cd usbrelay

sudo apt install -y libhidapi-dev
make
sudo make install

sudo usermod -a -G plugdev $USER
sed -e 's/usbrelay/plugdev/' 50-usbrelay.rules | sudo tee /etc/udev/rules.d/50-usbrelay.rules
sudo udevadm control -R
# also reconnect to ssh at this point to apply the new user group

ls -la /dev/hidraw* /dev/usbrelay*
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

# you can set pins via this short name
usbrelay _1=0
# you can also use the device path
usbrelay /dev/hidraw0_1=0
usbrelay /dev/usbrelay5-1_1=0
```

# Set up access to USB relay from the UI

```bash
sudo usermod -a -G plugdev kvmd

# select a relay to use
# note that /dev/usbrelay* is a physical device path
# that wiil change if you plug the device into a different USB port
ls -la /dev/usbrelay*
relay=
# example: relay=/dev/usbrelay5-1

# create the script that will actually switch the relay
# you will likely need to change /dev/usbrelay5-1_1 to your own path
sudo mkdir -p /etc/kvmd/scripts/
sudo tee << EOF /etc/kvmd/scripts/usb-relay-press.sh
#!/bin/bash
set -e

# check device list in case this script stopped working
# ls -la /dev/usbrelay*

delay=\$1
usbrelay -q ${relay}_1=1
sleep \$delay
usbrelay -q ${relay}_1=0
EOF
sudo chmod +x /etc/kvmd/scripts/usb-relay-press.sh

 sudo tee << EOF /etc/kvmd/override.d/0-power-relay-gpio.yaml
kvmd:
  gpio:
    drivers:
      power-relay-short-press:
        type: cmd
        cmd:
        - /bin/bash
        - /etc/kvmd/scripts/usb-relay-press.sh
        - 0.01
      power-relay-press-5s:
        type: cmd
        cmd:
        - /bin/bash
        - /etc/kvmd/scripts/usb-relay-press.sh
        - 5
      power-relay-press-10s:
        type: cmd
        cmd:
        - /bin/bash
        - /etc/kvmd/scripts/usb-relay-press.sh
        - 10
    scheme:
      power_button:
        driver: power-relay-short-press
        pin: 0
        mode: output
        switch: false
      power_button_5s:
        driver: power-relay-press-5s
        pin: 0
        mode: output
        switch: false
      power_button_10s:
        driver: power-relay-press-10s
        pin: 0
        mode: output
        switch: false
EOF
 [ -f /etc/kvmd/override.d/99-gpio-view.yaml ] || sudo tee << EOF /etc/kvmd/override.d/99-gpio-view.yaml
kvmd:
  gpio:
    view:
      table:
EOF
 grep "# power-relay" /etc/kvmd/override.d/99-gpio-view.yaml || sudo tee -a << EOF /etc/kvmd/override.d/99-gpio-view.yaml
      # power-relay
      - []
      - ["power_button|confirm|Power button"]
      - ["power_button_5s|confirm|Power button 5s"]
      - ["power_button_10s|confirm|Power button 10s"]
EOF

# restart `kvmd` to pick up new config and the plugdev group
sudo systemctl restart kvmd
sudo systemctl status kvmd
```
