
https://github.com/AirenSoft/OvenMediaEngine

https://airensoft.gitbook.io/ovenmediaengine/getting-started/getting-started-with-docker

ome-local.example.duckdns.org

Streaming:
From quickstart: https://airensoft.gitbook.io/ovenmediaengine/quick-start
rtmp://ome-local.example.duckdns.org:1935/app
key: stream

Key may be whatever, you just need to match it in OBS and in stream link.

WebRTC playback:
ws://[dns-name]:[port]/app/stream
ws://[ip-addr]:[port]/app/stream
With TLS termination:
wss://[dns-name]:[port]/app/stream

Port may be ommitted if it is 80 for plain connection or 443 for encrypted connection.

wss://ome-signal.example.duckdns.org/app/stream

llhls playback:
http://ome-local.example.duckdns.org:3333/app/stream/llhls.m3u8

# Extract config from docker image

```bash
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/origin_conf/Server.xml > ome-config.xml
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/edge_conf/Server.xml > ome-edge-config.xml
```

# using websocket tls termination

Websocket connection doesn't have a promt for untrusted certificate.
If you are using a staging certificate, the connection will fail because of untrusted certificate.

A workaround is to open the page from the WSS address as an HTTP page and accept the certificate.

# Proper website

https://github.com/zibbp/radium/tree/next

# OBS capture certain audio from one window

Starting from v28 there is a built-in feature for this, but there is also a more feature-rich plugin:
https://github.com/bozbez/win-capture-audio
