
# IP KVM for non-RPi devices

References:
- https://github.com/srepac/kvmd-armbian

For Orange Pi Zero 2w you need to disable `fix-nfs-msd` in the script.
Also, you may need to replace `gpiod.LineEvent` manually.
