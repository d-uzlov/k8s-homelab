# Outline client on OpenWRT

In this guide, we set up the `shadowsocks-libev` Outline/Shadowsocks client.
As a result, all traffic of devices connected to that OpenWRT instance will be routed through Outline.

N.B.: This guide doesn't cover domain-based conditional routing.

# Sources

- [shadowsocks-libev setup guide (in Russian)](https://habr.com/ru/articles/748408/)

# Prerequisites

- [OpenWRT](./openwrt.md)

# Installation

```shell
opkg update
opkg install shadowsocks-libev-ss-local shadowsocks-libev-ss-redir
opkg install shadowsocks-libev-ss-rules shadowsocks-libev-ss-tunnel
opkg install luci-app-shadowsocks-libev
opkg install coreutils-base64
```

```shell
ADDRESS='ss://<base64 encoded password and encryption method>@<server IP>:<port>/?outline=1'
ADDRESS_REGEX='ss://([A-Za-z0-9]+)@([.0-9]+):([0-9]+)/\?outline=1'
[[ $ADDRESS =~ $ADDRESS_REGEX ]]
BASE64_PASSWORD=${BASH_REMATCH[1]}
OUTLINE_IP=${BASH_REMATCH[2]}

OUTLINE_PORT=${BASH_REMATCH[3]}
LEFT_PORT=$(($OUTLINE_PORT-1))
RIGHT_PORT=$(($OUTLINE_PORT+1))

METHOD_PASSWORD=$(echo $BASE64_PASSWORD | base64 -d)
PASSWORD_REGEX='([a-z0-9-]+):([A-Za-z0-9]+)'
[[ $METHOD_PASSWORD =~ $PASSWORD_REGEX ]]
OUTLINE_METHOD=${BASH_REMATCH[1]}
OUTLINE_PASSWORD=${BASH_REMATCH[2]}

cat <<EOF > /etc/config/shadowsocks-libev
config server 'sss0'
        option server '$OUTLINE_IP'
        option server_port '$OUTLINE_PORT'
        option password '$OUTLINE_PASSWORD'
        option method '$OUTLINE_METHOD'

config ss_redir 'hj'
        option server 'sss0'
        option local_address '0.0.0.0'
        option local_port '1100'
        option mode 'tcp_and_udp'
        option timeout '60'
        option fast_open '1'
        option reuse_port '1'

config ss_rules 'ss_rules'
        option src_default 'checkdst'
        option dst_forward_recentrst '0'
        option redir_tcp 'hj'
        option redir_udp 'hj'
        option local_default 'forward'
        option dst_default 'forward'
        option nft_tcp_extra 'tcp dport { 80-$LEFT_PORT, $RIGHT_PORT-65535 }'
        option nft_udp_extra 'udp dport { 53-65535 }'
EOF
```

# Check if your Outline client works

```shell
wget -qO- http://ipecho.net/plain | xargs echo
```

You should see the IP of the Outline server.
