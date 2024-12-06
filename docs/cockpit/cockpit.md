
# Cockpit

References:
- https://cockpit-project.org/running.html#debian
- https://www.apalrd.net/posts/2023/ultimate_nas/

```bash
. /etc/os-release
 sudo tee /etc/apt/sources.list.d/backports.list << EOF
deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main contrib
deb-src http://deb.debian.org/debian ${VERSION_CODENAME}-backports main contrib
EOF
sudo apt update

. /etc/os-release
 sudo tee /etc/apt/preferences.d/90-cockpit << EOF
Package: cockpit*
Pin: release n=${VERSION_CODENAME}-backports
Pin-Priority: 950
EOF
apt-cache policy

sudo apt install -y cockpit

curl -sSL https://repo.45drives.com/setup > ./45drives-setup.sh
chmod +x ./45drives-setup.sh
sudo ./45drives-setup.sh
sudo apt-get update

sudo apt install -y open-iscsi samba nfs-kernel-server nfs-common
sudo apt install -y cockpit-file-sharing cockpit-navigator cockpit-identities
# sudo apt install -y -t ${VERSION_CODENAME}-backports cockpit-machines
sudo apt install -y cockpit-zfs-manager
sudo apt install -y cockpit-benchmark
# cockpit-file-sharing is samba + nfs
# cockpit-navigator is a web ui file manager
# cockpit-identities is user management
# cockpit-machines is VM management
# cockpit-benchmark allows you to run fio from web UI
```

Go to: `https://ip:9090`

Use your linux account for login.

# Network

Some functions of Cockpit do not work without NetworkManager.
Namely, `Software updates` module.

```bash
 sudo tee /etc/netplan/0-network-manager.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
sudo systemctl disable systemd-networkd-wait-online.service
```

# Fonts

Some fonts that are needed for Cockpit are missing from Debian.
You can copy them from [here](./cockpit/fonts/).

Put files into `/usr/share/cockpit/base1/fonts/`.

```bash
cockpitHost=
scp ./docs/cockpit/fonts/* $cockpitHost:./fonts/
ssh cockpit sudo mv ./fonts/ /usr/share/cockpit/base1/fonts/
```

References:
- https://www.reddit.com/r/HomeServer/comments/1axk02h/guide_to_use_debian_w_cockpit_and_45drives/
- https://nextcloud.fstech.ltd/s/ixz32b2BWEiADwF

# ZFS

```bash
. /etc/os-release
sudo tee /etc/apt/preferences.d/90-zfs << EOF
Package: src:zfs-linux
Pin: release n=${VERSION_CODENAME}-backports
Pin-Priority: 990
EOF

sudo apt install -y dpkg-dev linux-headers-generic linux-image-generic
sudo apt install -y zfs-dkms zfsutils-linux
```

# iSCSI

References:
- https://github.com/45Drives/cockpit-file-sharing/issues/109

Seems like SCST is a legacy project, which is used by cockpit but not by democratic-csi?

```bash
. /etc/os-release
sudo tee /etc/apt/preferences.d/90-scst << EOF
Package: scst-dkms
Pin: release n=${VERSION_CODENAME}-backports
Pin-Priority: 990
EOF

sudo apt install -y scst-dkms

sudo tee /etc/modules-load.d/scst.conf << EOF
scst_vdisk
iscsi_scst
scst
EOF
sudo systemctl restart systemd-modules-load.service
```
