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

# Step 1. Enable IP forwarding on Proxmox

```shell
sudo tee /etc/sysctl.d/ip_forward.conf << EOF
net.ipv4.ip_forward=1
EOF
# reload rules from /etc/sysctl.d/
sudo sysctl --system
sudo sysctl net.ipv4.ip_forward
```

# Step 2. Set up a Debian container

On this stage, it's assumed you already have a Debian container image in Proxmox.

## Create the container

Important settings when creating a container:

- `General`: uncheck `Unprivileged container`
- Disk: at least 5 GiB
- Memory: at least 128 MiB

After creating go to `Options` and enable nesting feature.

Edit container config:

```bash
containerId=100
# https://forum.proxmox.com/threads/pve-7-openvpn-lxc-problem-cannot-open-tun-tap-dev.92893/
sudo tee --append /etc/pve/lxc/$containerId.conf << EOF
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
lxc.cgroup2.devices.allow: c 10:200 rwm
EOF

# start and enter the container
sudo pct start $containerId
sudo pct enter $containerId
```

# Container initial setup

Commands should be run in the container:

```bash
apt update
apt full-upgrade -y
apt install -y curl htop

tee /etc/sysctl.d/ip_forward.conf << EOF
net.ipv4.ip_forward=1
EOF
# reload rules from /etc/sysctl.d
sysctl --system
sysctl net.ipv4.ip_forward

curl https://get.docker.com | bash
```

# Step 3. OpenVPN setup

## Create the files for container settings

```shell
tee sysctl.conf << EOF
net.ipv4.ip_forward=1
EOF

 tee docker-compose.yaml << EOF
name: openvpn
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
```

## Generate base server settings

```shell
# This address is used in default client configuration files and certificates
publicOpenvpnUrl=
docker compose run --rm openvpn ovpn_genconfig -u udp://$publicOpenvpnUrl
docker compose run --rm openvpn ovpn_initpki
```

You will have to manually edit `openvpn-data/conf/openvpn.conf` because OpenVPN doesn't support config directories:

```shell
nano openvpn-data/conf/openvpn.conf
```

### Routes to LAN and OpenVPN network

Replace the default route setting `route 192.168.254.0 255.255.255.0`
with routes to your LAN and the OpenVPN network:

```conf
push "route <local_subnet> 255.255.255.0"
push "route <OpenVPN_subnet> 255.255.255.0"
```

### DNS

N.B. You can see the `<OpenVPN_subnet>` on the first line of the generated config file:

```conf
server 192.168.255.0 255.255.255.0
```

In this example, the server will take the IP `192.168.255.1` and give the clients IPs from the rest of the range.

(Optional) Replace Google DNS:

```conf
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
```

with your local DNS:

```conf
push "dhcp-option DNS <local_DNS>"
```

### Individual IPs and IP persistency

And add some useful options:

```
# Assign each client an individual IP instead of /30 subnet.
# Defaults to "net30" for compatibility with outdated Windows clients
topology subnet
# Persistently store IP associations in this file
ifconfig-pool-persist ipp.txt
```

### Final server configuration

In the end, your `openvpn.conf` will look like this:

```conf
server 192.168.255.0 255.255.255.0
verb 3
key /etc/openvpn/pki/private/example.duckdns.org.key
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/example.duckdns.org.crt
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
push "route <local_subnet> 255.255.255.0"

### Push Configurations Below
push "block-outside-dns"
push "dhcp-option DNS <DNS_server>"
push "comp-lzo no"
```

## Start the server

```shell
docker compose up -d
```

# Step 4. Set up a client

```shell
# set to any alphanumeric value
client_name=
# with a passphrase (recommended)
docker compose exec openvpn easyrsa build-client-full $client_name
# without a passphrase (not recommended)
docker compose exec openvpn easyrsa build-client-full $client_name nopass
# Retrieve the client configuration with embedded certificates
docker compose exec openvpn ovpn_getclient $client_name > $client_name.ovpn
```

The freshly generated client configuration is ready-to-use if your server is available via the default port `1194`.
If not, edit the line 6 in `$client_name.ovpn`:

```
remote <your_server_public_address> <port> udp
```

Remove `redirect-gateway` if you don't need the openvpn server to act as a default gateway.

Download the client app [here](https://openvpn.net/client/).
