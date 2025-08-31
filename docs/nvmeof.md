
# NVMe-oF

NVMe-oF is a way to run NVMe over some network.

For best performance you would want to use RDMA,
but NVMe-over-TCP is also possible.

Tutorials:
- https://futurewei-cloud.github.io/ARM-Datacenter/qemu/nvme-of-tcp-vms/
- https://blogs.oracle.com/linux/post/nvme-over-tcp

Discussions:
- https://www.truenas.com/community/threads/nvme-of-support-planned.103500/
- https://forum.level1techs.com/t/how-can-i-help-with-the-new-truenas-100g-testing/179052/6

nvmetcli man page:
- https://www.mankier.com/8/nvmetcli

Some maybe related drivers:
- https://network.nvidia.com/products/adapter-software/ethernet/windows/winof-2/

# Set up target on a Linux system

```bash

apt-get install nvme-cli

sudo modprobe nvmet
sudo modprobe nvmet-tcp

# on host
sudo mkdir /sys/kernel/config/nvmet/subsystems/nvmet-test
echo 1 | sudo tee -a /sys/kernel/config/nvmet/subsystems/nvmet-test/attr_allow_any_host > /dev/null
sudo mkdir /sys/kernel/config/nvmet/subsystems/nvmet-test/namespaces/1
sudo echo -n /dev/zvol/ssd/prox/test-nvme | sudo tee -a /sys/kernel/config/nvmet/subsystems/nvmet-test/namespaces/1/device_path > /dev/null
echo 1 | sudo tee -a /sys/kernel/config/nvmet/subsystems/nvmet-test/namespaces/1/enable > /dev/null

sudo mkdir /sys/kernel/config/nvmet/ports/1
echo 0.0.0.0 | sudo tee -a /sys/kernel/config/nvmet/ports/1/addr_traddr > /dev/null
echo tcp | sudo tee -a /sys/kernel/config/nvmet/ports/1/addr_trtype > /dev/null
echo 4420 | sudo tee -a /sys/kernel/config/nvmet/ports/1/addr_trsvcid > /dev/null
echo ipv4 | sudo tee -a /sys/kernel/config/nvmet/ports/1/addr_adrfam > /dev/null
sudo ln -s /sys/kernel/config/nvmet/subsystems/nvmet-test/ /sys/kernel/config/nvmet/ports/1/subsystems/nvmet-t

dmesg | grep "nvmet_tcp"

```

# Setup via nvmetcli

```bash

cd /subsystems
create test-v2
cd test-v2
set attr allow_any_host=1
cd namespaces
create 1
cd 1
set device path=/dev/zvol/pool-name/test-nvmeof/v2
set device path=/dev/nvme1n1
set device path=/dev/nvme1
enable
disable

cd /ports/1/subsystems/
create test-v2

```

References:
- https://man.archlinux.org/man/extra/nvmetcli/nvmetcli.8.en
- https://wiki.archlinux.org/title/NVMe_over_Fabrics

# Discover targets from a Linux client

```bash

sudo modprobe nvme
sudo modprobe nvme-tcp

# list targets available on server_ip
# you can't use domain name, you should resolve it to ip
sudo nvme discover --transport tcp --traddr $server_ip -s 4420

sudo nvme connect --transport tcp --traddr $server_ip --trsvcid 4420 --nr-io-queues 4 --nqn $subnqn

sudo nvme list
sudo nvme list-subsys

sudo nvme disconnect -n $subnqn

```

# Install NVMe-oF client on Windows:

If you have some approved corporative email:
- Download from here: https://www.starwindsoftware.com/starwind-nvme-of-initiator#download
- You will need to request `NVMe-oF Initiator Free` (make sure you don't select non-free version),
filling in you personal info.
- From what I see, the requests are processed automatically.
- You will receive an email containing download link and a personal license key (without an expiration)

If you don't have a corporate email:
- Try sending an email to StarWind support.

# Testing on Windows

Random 4k write is 2.5x faster.

Other metrics are not affected.

NVMe-oF driver from StarWind sometimes hangs
and locks out the whole disk management,
as well as iSCSI management.
