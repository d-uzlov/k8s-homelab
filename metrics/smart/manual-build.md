
```bash

# sudo apt remove smartmontools
# we are installing smartctl from sources because
# - most distributions have outdated version
# - smartctl doesn't have docker image, or anything similar
# - smartctl is a broken mess that absolutely requires updates
# sudo apt install make g++
# https://github.com/smartmontools/smartmontools/releases
# wget -q https://github.com/smartmontools/smartmontools/releases/download/RELEASE_7_5/smartmontools-7.5.tar.gz
# tar zxvf smartmontools-7.5.tar.gz
# cd smartmontools-7.5
# ./configure
# make
# sudo make install
# cd ..

```
