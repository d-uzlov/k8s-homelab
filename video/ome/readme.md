
# OvenMediaEngine

https://github.com/AirenSoft/OvenMediaEngine

https://airensoft.gitbook.io/ovenmediaengine/getting-started/getting-started-with-docker

This is a video streaming engine that supports low latency streams.

# Deploy

```bash
kl create ns ome
kl apply -k ./video/ome/

# create loadbalancer service
kl apply -k ./video/ome/loadbalancer/
# get assigned IP to set up DNS or NAT port-forwarding
kl -n ome get svc

kl label ns --overwrite ome copy-wild-cert=main
kl apply -k ./video/ome/ingress-wildcard/
```

# Load balancer services

There are 2 load balancer services:
- Provide: for streaming from source to server
- WebRTC: for streaming from server to client

You can get their external IPs:
```bash
kl -n ome get svc provide webrtc-ice
```

If you are behind NAT you need to set up port forwarding.

You can skip Provide service if you don't want to stream from outside of LAN.

You can skip WebRTC if you don't plan on using WebRTC for watching video.

WebRTC forwarded ports must match ports of the service itself.

WebRTC determines host IP automatically, and clients try to connect to it.
If your service IP does not match the IP that the server can detect using "show my IP" external services,
you need to set `OME_WEBRTC_CANDIDATE_IP` environment variable to point to correct IP.

# How to stream

- [optional] Set up local DNS to point to `provide_ip`
- Set up OBS
- - This is info from quickstart: https://airensoft.gitbook.io/ovenmediaengine/quick-start
- - Go to `Settings -> Stream`
- - Set server: `rtmp://<provide_ip or DNS>:1935/app`
- - Set stream key: an arbitrary string
- - `/app` corresponds to `<Name>app</Name>` in `ome-config.xml`, and can be changed by editing the config.

# Playback

- Deploy [OvenPlayer](../ovenplayer/readme.md)
- Create stream link that corresponds to your config and OBS settings

# Playback with WebRTC (sub-second latency)

- Streaming via HTTP: `ws://<ingress_ip or DNS>:3333/app/<stream-key>`
- Streaming via HTTPS: `wss://<ingress_public_domain>/app/<stream-key>`
- `/app` and `<stream-key>` must match OSB settings
- WebSockets forbid mixed content.
- - If you open OvenPlayer via HTTPS Ingress,
    plain HTTP playback will not work, and vice versa.
- Make sure to [setup port forwarding](#load-balancer-services)

# LLHLS playback (latency 1-3 seconds)

- Streaming via HTTP: `http://<ingress_ip or DNS>:3333/app/<stream-key>/llhls.m3u8`
- Streaming via HTTPS: `https://<ingress_public_domain>/app/<stream-key>/llhls.m3u8`

# Extract config from image

Obviously, you need to disable config replacement in the deployment if you want to get the default config.

```bash
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/origin_conf/Server.xml > ome-config.xml
kl -n ome exec deployments/ovenmediaengine -it -- cat /opt/ovenmediaengine/bin/edge_conf/Server.xml > ome-edge-config.xml
```

# Using WebSocket with untrusted TLS termination

WebSocket connection doesn't have a prompt for untrusted certificate.
If you are using a staging certificate, the connection will fail because of untrusted certificate.

A workaround is to open the page from the WSS address as an HTTP page and accept the certificate.

# OBS capture certain audio from one window

Starting from v28 there is a built-in feature for this, but there is also a more feature-rich plugin:
https://github.com/bozbez/win-capture-audio
