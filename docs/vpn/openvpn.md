# OpenVPN

In this guide, we set up a Docker-run OpenVPN container in Proxmox, so that the entire local network
is accessible via VPN by any client connected. In short, we need to:
- create a privileged container in Proxmox and enable nesting in it;
- deploy an OpenVPN image for Docker within that container;
- enable IP forwarding in the hypervisor and all the nested containers;
- add some settings to the network configuration OpenVPN server sends to its clients:
  - route to the local network via the OpenVPN server (necessary),
  - local DNS server (optional).

# Sources

- [OpenVPN docker image by kylemanna](https://hub.docker.com/r/kylemanna/openvpn/)
- [Documentation for the Docker image](https://github.com/kylemanna/docker-openvpn)
- [IP forwarding activation](https://www.dmosk.ru/miniinstruktions.php?mini=openvpn-local-network)

## Step 1. Enable IP forwarding on Proxmox

```shell
tee /etc/sysctl.d/ip_forward.conf <<EOF
net.ipv4.ip_forward=1
EOF
# reload rules from /etc/sysctl.d
sysctl --system
```

## Step 2. Set up a Debian container

On this stage, it's assumed you already have a Debian container image in Proxmox.

### Create the container

- Start creating a new container and disable the `Unprivileged container` option on the `General` tab.
- Enable DHCP on the `Network` tab.
- The container needs at least 1 vCPU, 128 MB of RAM, 0 MB of swap, and 5 GB of disk space.

Don't start the container after creating. Docker needs to have nesting enabled, so:
- open the file `/etc/pve/lxc/<CONTAINER_ID>.conf` on the Proxmox machine,
- enable nesting: `features: nesting=1`,
- enable the capability to create devices:

  ```
  lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
  lxc.cgroup2.devices.allow: c 10:200 rwm 
  ```
  
Your container config file will finally look like this:

```
arch: amd64
cores: 1
features: nesting=1
hostname: openvpn
memory: 256
net0: name=eth0,bridge=vmbr1,firewall=1,hwaddr=FF:…:99,ip=dhcp,type=veth
ostype: debian
rootfs: …,size=5G
swap: 0
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
lxc.cgroup2.devices.allow: c 10:200 rwm
```

`lxc.cgroup2` hack that allows device creation is taken from
[this](https://forum.proxmox.com/threads/pve-7-openvpn-lxc-problem-cannot-open-tun-tap-dev.92893/)
thread on the Proxmox forum.

Start the container.

### Enable IP forwarding

```shell
tee /etc/sysctl.d/ip_forward.conf <<EOF
net.ipv4.ip_forward=1
EOF
# reload rules from /etc/sysctl.d
sysctl --system
```

## Step 3. Set up the server

All the following commands are run in the Debian container shell.

### Install Docker on the Debian container

```shell
apt update && apt install curl -y && curl https://get.docker.com | bash
```

### Configure the server image

#### Create the files for container settings

```shell
tee sysctl.conf <<EOF
net.ipv4.ip_forward=1
EOF

tee docker-compose.yml <<EOF
services:
  openvpn:
    cap_add:
     - NET_ADMIN
    image: kylemanna/openvpn
    container_name: openvpn
    ports:
     - 1194:1194/udp
    restart: always
    volumes:
     - ./openvpn-data/conf:/etc/openvpn
     - ./sysctl.conf:/etc/sysctl.conf
EOF

# The file to persistently store clients' IP associations in. See "ifconfig-pool-persist" option below
touch ipp.txt
```

#### Generate base server settings

```shell
# This address is used in default client configuration files and certificates
export OPENVPN_SERVER="your_server_public_address"
docker compose run --rm openvpn ovpn_genconfig -u udp://$OPENVPN_SERVER
docker compose run --rm openvpn ovpn_initpki
```

You will have to manually edit `openvpn-data/conf/openvpn.conf` because OpenVPN doesn't support config directories:

```shell
nano openvpn-data/conf/openvpn.conf
```

#### Routes to LAN and OpenVPN network

Replace the default route setting `route 192.168.254.0 255.255.255.0`
with routes to your LAN and the OpenVPN network:

```
push "route <local_subnet> 255.255.255.0"
push "route <OpenVPN_subnet> 255.255.255.0"
```

#### DNS

N.B. You can see the `<OpenVPN_subnet>` on the first line of the generated config file:
```
server 192.168.255.0 255.255.255.0
```

In this example, the server will take the IP `192.168.255.1` and give the clients IPs from the rest of the range.

(Optional) Replace Google DNS:

```
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
```

with your local DNS:
```
push "dhcp-option DNS <local_DNS>"
```

#### Individual IPs and IP persistency

And add some useful options:

```
# Assign each client an individual IP instead of /30 subnet.
# Defaults to "net30" for compatibility with outdated Windows clients
topology subnet
# Persistently store IP associations in this file
ifconfig-pool-persist ipp.txt
```

#### Final server configuration

In the end, your `openvpn.conf` will look like this:

```
…
server 192.168.255.0 255.255.255.0
verb 3
key /etc/openvpn/pki/private/fulldungeon.duckdns.org.key
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/fulldungeon.duckdns.org.crt
dh /etc/openvpn/pki/dh.pem
tls-auth /etc/openvpn/pki/ta.key
key-direction 0
keepalive 10 60
persist-key
persist-tun

proto udp
# Rely on Docker to do port mapping, internally always 1194
port 1194
dev tun0
status /tmp/openvpn-status.log

user nobody
group nogroup
comp-lzo no

topology subnet
ifconfig-pool-persist ipp.txt

### Route Configurations Below
push "route 192.168.255.0 255.255.255.0"
push "route 192.168.88.0 255.255.255.0"

### Push Configurations Below
push "block-outside-dns"
push "dhcp-option DNS 192.168.88.63"
push "comp-lzo no"
```

## Step 4. Create a client configuration

```shell
export CLIENT_NAME="your_client_name"
# with a passphrase (recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENT_NAME
# without a passphrase (not recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENT_NAME nopass
# Retrieve the client configuration with embedded certificates
docker compose run --rm openvpn ovpn_getclient $CLIENT_NAME > $CLIENT_NAME.ovpn
```

The freshly generated client configuration is ready-to-use if your server is available via the default port `1194`.
If not, edit the line 6 in `$CLIENT_NAME.ovpn`:

```
remote <your_server_public_address> <port> udp
```

## Step 5. Start the server

```shell
docker compose up -d openvpn
```
