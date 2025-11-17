
# 3x-ui

References:
- https://github.com/MHSanaei/3x-ui
- https://github.com/XTLS/Xray-core
- https://xtls.github.io/en/config/routing.html#routingobject
- https://xtls.github.io/en/config/inbounds/wireguard.html

Additional links:
- https://github.com/XTLS/RealiTLScanner
- https://github.com/v2fly/geoip
- https://github.com/v2fly/domain-list-community
- https://github.com/v2ray/discussion/issues/148
- https://github.com/InvisibleManVPN/InvisibleMan-XRayClient

# Install 3x-ui

```bash
curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh | sudo bash

sudo systemctl status x-ui --no-pager
sudo journalctl -u x-ui
sudo x-ui help
# print config for access
sudo x-ui settings
ll /usr/local/x-ui/bin/
```

# Change SSH port

```bash
# generate port in a random number generator
port=
sudo tee << EOF /etc/ssh/sshd_config.d/0-port.conf
Port $port
EOF
# existing ssh sessions will survive sshd restart
sudo systemctl restart sshd
sudo netstat -tuplen
# open a new session to check that you can access the new port
# if something goes wrong, you can use an old session to fix things
```

# Certificate

Look here for instructions for your DNS provider:
- https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_dynu

```bash
sudo apt install -y cron
# acme.sh seems to work without socat but complains in logs
sudo apt install -y socat

email=
curl https://get.acme.sh | sh -s "email=$email"

# example for dynu
export Dynu_ClientId=
export Dynu_Secret=
domain=
acme.sh --issue --server letsencrypt --dns dns_dynu -d "$domain" -d "*.$domain"

# show currently existing certificates
ll ~/.acme.sh/*_ecc/*
```

# 3x-ui setup

- Panel Settings -> Listen IP: 127.0.0.1
- Panel Settings -> Public Key Path: /path/to/fullchain.cer
- Panel Settings -> Private Key Path: /path/to/domain.key
- Xray Configs -> General -> Overall Routing Strategy:
- - `AsIs`: ignore all IP rules
- - `IPIfNonMatch`: if no domain match found in rules, resolve domain and re-match using IP
- - (recommended for sanity) `IPOnDemand`: if there are any IP rules, resolve domain and match both IP and domain rules

```bash
# setup ssh port forwarding
ssh -L local_ip:2053:127.0.0.1:2053 server_address
```

- Inbounds -> Add Inbound
- - Protocol: vless
- - Port: 443
- - Security: Reality
- - Dest (target): 127.0.0.1:port
- - SNI: your server public domain
- - Client -> Flow: xtls-rprx-vision
- - Click "Get new cert" at the bottom

```bash
sudo apt-get install -y nginx

fullchain_cert=
# example: fullchain_cert=$HOME/.acme.sh/example.com_ecc/fullchain.cer
cert_key=
# example: cert_key=$HOME/.acme.sh/example.com_ecc/example.com.key
redirect=
# example: redirect=http://127.0.0.1:1234
# only used in file name, set to user-readable value
site_name=

ll /etc/nginx/sites-available/ /etc/nginx/sites-enabled/
sudo tee /etc/nginx/sites-available/$site_name << EOF
# https redirect
server {
  listen 80;
  server_name _;
  return 301 https://\$host\$request_uri;
}

server {
  # listen on port 444 to avoid interference with xray
  listen 127.0.0.1:444 ssl;
  server_name _;

  ssl_certificate $fullchain_cert;
  ssl_certificate_key $cert_key;

  location / {
    proxy_ssl_server_name on;
    proxy_pass $redirect;
    proxy_redirect off;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF

sudo ln -s /etc/nginx/sites-available/$site_name /etc/nginx/sites-enabled/$site_name
sudo rm -f /etc/nginx/sites-enabled/default

# check config
sudo nginx -t

sudo systemctl restart nginx
sudo systemctl status nginx --no-pager
```

# Android client

- Install Hiddify
- Scan QR code
- Make sure that server domain name is correct
- Make sure flow is xtls-rprx-vision
