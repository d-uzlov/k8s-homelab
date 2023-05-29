
# OvenMediaEngine

https://github.com/AirenSoft/OvenMediaEngine

https://airensoft.gitbook.io/ovenmediaengine/getting-started/getting-started-with-docker

This is a video streaming engine that supports low latency streams

# Deploy

```bash
kl create ns ome
kl label ns ome copy-wild-cert=example

# Init once
mkdir -p ./streaming/ome/env
cat <<EOF > ./streaming/ome/env/ingress.env
public_domain=ome-signal.example.duckdns.org

wildcard_secret_name=wild--example.duckdns.org

allowed_sources=10.0.0.0/16,1.2.3.4
EOF
cat <<EOF > ./streaming/ome/env/services.env
provide_ip=10.0.3.16
stream_ip=10.0.3.17
EOF

kl apply -k ./streaming/ome/
```

# How to stream

1. [optional] Set up local dns to point to `provide_ip` from `services.env`

2. Set up OBS

From quickstart: https://airensoft.gitbook.io/ovenmediaengine/quick-start

```s
Settings -> Stream
Server: rtmp://<provide_ip or DNS>:1935/app
Stream key: stream
```

`/<app>` can be configured in the `ome-config.xml`

Stream key may be an arbitrary string.

# Playback with WebRTC (sub-second latency)

1. Set up port forwarding

Streaming with WebRTC requires open ports.

This deployment creates a LoadBalancer service with ip `stream_ip`.
You need to set up port forwarding from matching external port to specified address.
You need to forward both ports from the `webrtc-ice` service.

2. Deploy [OvenPlayer](../ovenplayer/)

3. Create stream link

```s
# plain HTTP in local network
ws://<stream_ip>:3333/app/<stream-key>
ws://<local DNS>:3333/app/<stream-key>
# HTTPS through ingress
wss://<public_domain>/app/<stream-key>
```

WebSockets forbid mixed content.
Meaning if you open OvenPlayer via Ingress with proper certificate,
plain HTTP link will not work, and vice versa.

# LLHLS playback (latency 1-3 seconds)

Unlike WebRTC, LLHLS doesn't need port forwarding.

1. Deploy [OvenPlayer](../ovenplayer/)

2. Create stream link

```s
# plain HTTP in local network
http://<stream_ip>:3333/app/<stream-key>/llhls.m3u8
http://<local DNS>:3333/app/<stream-key>/llhls.m3u8
# HTTPS through ingress
https://<public_domain>/app/<stream-key>/llhls.m3u8
```

# Extract config from docker image

Obviously, you need to disable config replacement in the deployment if you want to get the default config.

```bash
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/origin_conf/Server.xml > ome-config.xml
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/edge_conf/Server.xml > ome-edge-config.xml
```

# Using WebSocket with untrusted TLS termination

Websocket connection doesn't have a promt for untrusted certificate.
If you are using a staging certificate, the connection will fail because of untrusted certificate.

A workaround is to open the page from the WSS address as an HTTP page and accept the certificate.

# OBS capture certain audio from one window

Starting from v28 there is a built-in feature for this, but there is also a more feature-rich plugin:
https://github.com/bozbez/win-capture-audio
