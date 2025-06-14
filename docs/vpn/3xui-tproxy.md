
# xray setup to use as local router

This file explains how to set up xray to be able to use it as a router.
I.e.: you set it as a default gateway, and all packets are routed via xray.

Packet-based routing as achieved via tproxy protocol.

References:
- https://xtls.github.io/ru/document/level-2/iptables_gid.html
- https://v2.hysteria.network/docs/advanced/TPROXY/#__tabbed_2_1
- https://serverfault.com/questions/1169137/how-do-i-send-all-tcp-and-udp-traffic-over-tproxy-without-making-a-loop
- https://xtls.github.io/ru/document/level-2/tproxy_ipv4_and_ipv6.html#%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-iptables

# xray preparation

Add the following to the xray inbound config:

```json
  {
    "port": 1234,
    "protocol": "dokodemo-door",
    "tag": "from-tproxy-1234",
    "settings": {
      "network": "tcp,udp",
      "followRedirect": true
    },
    "streamSettings": {
      "sockopt": {
        "tproxy": "tproxy"
      }
    }
  }
```

# System preparation

```bash

sudo tee /etc/sysctl.d/ip_forward.conf << EOF
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

xray_group=2101
sudo groupadd -g $xray_group xray-tproxy
getent group xray-tproxy | grep $xray_group

service_file=/etc/systemd/system/x-ui.service
{ grep Group= $service_file || sudo sed -i 's/\[Service]/[Service]\nGroup=xray-tproxy/' $service_file ; } && grep 'Group=xray-tproxy' $service_file

sudo systemctl daemon-reload
sudo systemctl restart x-ui
sudo systemctl status x-ui --no-pager

# check that process guid matches current settings
ps -o pid,uid,gid,group,supgid -p $(pgrep x-ui)
ps -o pid,uid,gid,group,supgid -p $(pgrep xray-linux)

# check that you have high enough ulimit
cat /proc/$(pgrep x-ui)/limits | grep -e "Max open files" -e ^Limit
# 524288 seems to be good enough

```

# System route setup

Adjust route table to be able to use tproxy.

Here we also set up systemd service to enable persistence for routing rules.

```bash

 sudo tee /usr/local/sbin/tproxy-route-setup.sh << EOF
#!/bin/sh

set -e

# if packet has fwmark=0x2, route to table 100
ip rule list | grep "from all fwmark 0x2 lookup 100" || { sudo ip rule add fwmark 0x2 table 100 && echo "added ip rule" ; } || echo "ip rule failed"

ip route flush table 100 || true
# - add to table 100
# - route_type=local: this destination is local, traffic will be looped back
# - default: matches 0.0.0.0/0
# Who the hell knows why this is needed...
# Every tproxy guide just says "add this route to make tproxy work".
# Nobody in the internet seems to have an answer, there are only "RTFM" references.
# The F manual aka linux kernel docs doesn't explain anything.
# https://docs.kernel.org/networking/tproxy.html
sudo ip route add table 100 local default dev lo && echo "added ip route"
EOF
 sudo tee /usr/local/sbin/tproxy-route-cleanup.sh << EOF
#!/bin/sh

set -e

while ip rule del from all fwmark 0x2 lookup 100 2> /dev/null; do true; done
ip route flush table 100 || true
EOF
sudo chmod +x /usr/local/sbin/tproxy-route-setup.sh /usr/local/sbin/tproxy-route-cleanup.sh

# create a systemd service to run this automatically on startup
 sudo tee /etc/systemd/system/tproxy-route-setup.service << EOF
[Unit]
Description=tproxy route setup
Before=shutdown.target
After=multi-user.target
After=network-online.target
Wants=network-online.target
Conflicts=shutdown.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
StandardInput=null
ProtectSystem=full
ProtectHome=true
ExecStart=/usr/local/sbin/tproxy-route-setup.sh
ExecReload=/usr/local/sbin/tproxy-route-cleanup.sh && /usr/local/sbin/tproxy-route-setup.sh
ExecStop=/usr/local/sbin/tproxy-route-cleanup.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart tproxy-route-setup
sudo systemctl enable tproxy-route-setup
sudo systemctl status tproxy-route-setup --no-pager
sudo journalctl -u tproxy-route-setup

# check that everything is working
ip rule list | grep "from all fwmark 0x2 lookup 100"
ip route show table 100 | grep "local default dev lo"

```

# iptables for forwarding

This redirects external traffic to xray instead of forwarding it by default.

This is required even if you only want local traffic forwarding.

```bash

sudo iptables -t mangle -N XRAY_PREROUTING
# skip chain for connections with special ranges as destination
sudo iptables -t mangle -A XRAY_PREROUTING --destination 0.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 10.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 127.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 169.254.0.0/16 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 172.16.0.0/12 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 192.168.0.0/16 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 224.0.0.0/4 -j RETURN
sudo iptables -t mangle -A XRAY_PREROUTING --destination 240.0.0.0/4 -j RETURN
# for everything else, use tproxy
# tproxy-mark must match fwmark from the 'ip rule add fwmark ...'
# --protocol is required by the tproxy target
sudo iptables -t mangle -A XRAY_PREROUTING --protocol tcp -j TPROXY --on-port 1234 --on-ip 127.0.0.1 --tproxy-mark 0x2
sudo iptables -t mangle -A XRAY_PREROUTING --protocol udp -j TPROXY --on-port 1234 --on-ip 127.0.0.1 --tproxy-mark 0x2
# send all incoming traffic to XRAY_PREROUTING chain (see PREROUTING in #iptables-chain-diagram)
sudo iptables -t mangle -A PREROUTING --protocol tcp -j XRAY_PREROUTING
sudo iptables -t mangle -A PREROUTING --protocol udp -j XRAY_PREROUTING

# show current config
sudo iptables -t mangle -S
# if you want to change something in the XRAY_PREROUTING chain, you can delete it to start from scratch
sudo iptables -t mangle -F XRAY_PREROUTING

```

Don't forget to set up persistence: [iptables-persistence](../linux-iptables.md#iptables-persistence)

# Traffic optimization?

hysteria documentation claims that adding the lines below
at the beginning of the XRAY_PREROUTING chain is beneficial for performance.

For me it completely broke routing. I don't fully understand why.
I leave it here for a historical reference, but I don't recommend using it.

```bash
sudo iptables -t mangle -A XRAY_PREROUTING --protocol tcp --match socket --transparent -j MARK --set-mark 0x2
sudo iptables -t mangle -A XRAY_PREROUTING --protocol udp --match socket --transparent -j MARK --set-mark 0x2
sudo iptables -t mangle -A XRAY_PREROUTING --match socket -j RETURN
```

Explanation for `--match socket`:

Source: https://ipset.netfilter.org/iptables-extensions.man.html

> socket
> This matches if an open TCP/UDP socket can be found
> by doing a socket lookup on the packet.
> It matches if there is an established or non-zero bound listening socket
> (possibly with a non-local address).
> The lookup is performed using the packet tuple of TCP/UDP packets,
> or the original TCP/UDP header embedded in an ICMP/ICPMv6 error packet.
>   --transparent Ignore non-transparent sockets.
>   --nowildcard  Do not ignore sockets bound to 'any' address.
>                 The socket match won't accept zero-bound listeners by default,
>                 since then local services could intercept traffic that would otherwise be forwarded.
>                 This option therefore has security implications when used
>                 to match traffic being forwarded to redirect such packets to local machine with policy routing.
>                 When using the socket match to implement fully transparent proxies bound to non-local addresses
>                 it is recommended to use the --transparent option instead.

# iptables for local traffic

This will redirect local traffic through xray.

This is optional.

```bash
sudo iptables -t mangle -N XRAY_OUTPUT
# skip XRAY_OUTPUT for xray itself, to prevent traffic loop
sudo iptables -t mangle -A XRAY_OUTPUT -m owner --gid-owner "$(stat -c "%g" /proc/$(pgrep xray-linux)/)" -j RETURN
# skip chain for connections with special ranges as destination
sudo iptables -t mangle -A XRAY_OUTPUT --destination 0.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 10.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 127.0.0.0/8 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 169.254.0.0/16 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 172.16.0.0/12 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 192.168.0.0/16 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 224.0.0.0/4 -j RETURN
sudo iptables -t mangle -A XRAY_OUTPUT --destination 240.0.0.0/4 -j RETURN
# for everything else, set fwmark to use table 100 and send traffic to PREROUTING chain
sudo iptables -t mangle -A XRAY_OUTPUT -j MARK --set-mark 0x2
sudo iptables -t mangle -A OUTPUT -p tcp -j XRAY_OUTPUT
sudo iptables -t mangle -A OUTPUT -p udp -j XRAY_OUTPUT

# show current config
sudo iptables -t mangle -S
# if you want to change something in the XRAY_OUTPUT chain, you can delete it to start from scratch
sudo iptables -t mangle -F XRAY_OUTPUT

```

Don't forget to set up persistence: [iptables-persistence](../linux-iptables.md#iptables-persistence)

# Test routing

Run on some other machine on your LAN:

```bash

curl icanhazip.com

ip r | grep default
# save output to restore it later
# for example:
# default via 10.5.0.1 dev eth0

sudo ip route delete default
sudo ip route add default via 10.5.10.10 dev eth0
ip r | grep default

curl icanhazip.com

# restore previous default route
sudo ip route delete default
sudo ip route add default via 10.5.0.1 dev eth0
```
