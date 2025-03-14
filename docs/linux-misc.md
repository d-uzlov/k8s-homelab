
# Flush dns cache

```bash

sudo resolvectl flush-caches

```

# Edit $PATH for sudo

```bash

# add `/usr/local/sbin` to `$PATH` for `sudoers`:
sudo visudo
# In the opened `nano` editor, add `/usr/local/sbin` to `$PATH`.
#     For example:
# Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin"

```

# Power state statistics

cX is core states.

pcX is package states.

Values are counters, how much time CPU has spent in this state.

```bash

sudo apt-get install -y linux-cpupower
sudo turbostat --Dump --quiet | egrep '^(pc|c)[0-9]' | sort -u
# example output:
# c1: 0000000000000000
# c3: 0000000000000000
# c6: 00001404C636CFBD
# c6: 000016F653F648C3
# c6: 00001899DB9C3AD7
# c6: 00001D1E4DEC1524
# c7: 0000C9A622D6B2B6
# c7: 0000DCEBBEE08425
# c7: 0000DE996658BF48
# c7: 0000ECD752BCEDFB
# pc10: 0000000000000000
# pc2: 000001E0649D420D
# pc3: 000000011ADB6C42
# pc6: 0000000000000000
# pc7: 0000000000000000
# pc8: 0000000000000000
# pc9: 0000000000000000

```

# Change hostname

Note: this doesn't work in Proxmox VMs.

```bash

sudo hostnamectl set-hostname km1
# optionally you can also update hosts
sudo nano /etc/hosts

```

# Fix 'too many open files' issue

```bash
# default values:
#   fs.inotify.max_user_watches=8192
#   fs.inotify.max_user_instances=128

# change permanently
# make sure that /etc/sysctl.conf
# or other files in /etc/sysctl.d/
# don't override these values
sudo tee /etc/sysctl.d/inotify.conf << EOF
fs.inotify.max_user_watches = 4194304
fs.inotify.max_user_instances = 65536
EOF
# reload rules from /etc/sysctl.d
sudo sysctl --system
# check new values
sudo sysctl fs.inotify

```

In `WSL 22.04.1 LTS 5.15.90.1-microsoft-standard-WSL2`
`fs.inotify.max_user_instances` seems to be stuck at 128 after reboot.
Manual `sysctl` call fixes it until the next reboot.

# Remove old kernels

```bash

sudo apt autoremove

# list remaining versions
dpkg -S /boot/vm*
# take package name from the beginning of the line
sudo apt remove --no-install-recommends --no-install-suggests linux-image-6.1.0-28-amd64 proxmox-kernel-6.8.12-8-pve-signed

```

# Fix files permissions

```bash
# remove extended ACLs
sudo setfacl -b -R *
sudo setfacl -b -R -d *
# remove executable bit from everything
sudo chmod -R a-x *
# add executable bit to folders
sudo chmod -R a+rwX *
```

References:
- https://superuser.com/questions/51838/recursive-chmod-rw-for-files-rwx-for-directories
