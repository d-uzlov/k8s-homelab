
# OvenMediaEngine

This is a video streaming engine that supports low latency streams.

References:
- https://hub.docker.com/r/airensoft/ovenmediaengine
- https://github.com/AirenSoft/OvenMediaEngine
- https://airensoft.gitbook.io/ovenmediaengine/getting-started/getting-started-with-docker

# Deploy

Generate passwords and set up config.

```bash
mkdir -p ./video/ome/common-env/env/
cat <<EOF > ./video/ome/common-env/env/passwords.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
EOF
cat <<EOF > ./video/ome/common-env/env/webrtc-address.env
# public address, resolvable from outside world
public=example.duckdns.org
# LAN address, in case you are behind NAT
local=webrtc-ice.ome.kubelb.lan
EOF
```

```bash
kl create ns ome
kl label ns ome pod-security.kubernetes.io/enforce=baseline

kl -n ome apply -f ./network/network-policies/deny-ingress.yaml
kl -n ome apply -f ./network/network-policies/allow-same-namespace.yaml

# for any deployment
kl apply -k ./video/ome/svc-streamer/

# origin deployment
# choose one configuration, or deploy several configs
kl apply -k ./video/ome/origin-cpu/
kl apply -k ./video/ome/origin-nvidia/

# only works with a single origin instance
kl apply -k ./video/ome/svc-viewer-origin/

# works with any amount of origins but more complex
kl apply -k ./video/ome/edge/
kl apply -k ./video/ome/svc-viewer-edge/
kl apply -k ./video/ome/redis/
# restart origin servers, or they won't connect to redis
kl -n ome delete pod -l app=ovenmediaengine,ome-type=origin
# Edge should not be scaled!
# If you have 2 replicas, and control plane connection (`viewer` svc via ingress)
# and data plane connection (`webrtc` svc) connect to different instances, issues are very likely.
# Scaling is only possible if you create a different deployment, with separate ingress and webrtc svc.

# if you are using ingress
kl label ns --overwrite ome copy-wild-cert=main
kl apply -k ./video/ome/ingress-wildcard/
kl -n ome get ingress

# if you are using gateway api
kl apply -k ./video/ome/ingress-route/
kl apply -k ./video/ome/api-route/
kl -n ome describe httproute
kl -n ome get httproute

kl -n ome get pod -o wide
kl -n ome get svc
```

# Cleanup

```bash
kl delete -k ./video/ome/edge/
kl delete -k ./video/ome/redis/
kl delete -k ./video/ome/origin-cpu/
kl delete -k ./video/ome/origin-nvidia/
kl delete -k ./video/ome/ingress-wildcard/
kl delete -k ./video/ome/ingress-route/
kl delete -k ./video/ome/svc-viewer-origin/
kl delete -k ./video/ome/svc-viewer-edge/
kl delete -k ./video/ome/svc-streamer/
kl delete ns ome
```

# Edge debug

```bash
# First of all, restart the stream. Sometimes stream just doesn't get registered, and restart helps.
# check that redis contains a record for your stream
redis_pass=$(kl -n ome get secret redis-password --template "{{.data.redis_password}}" | base64 --decode)
kl -n ome exec deployments/redis -- redis-cli -a "$redis_pass" keys "*"

kl -n ome logs deployments/ome-edge
```

# Hardware acceleration on NVidia GPUs

Prerequisites:
- [NVidia device plugin](../../hardware/nvidia-device-plugin/readme.md)

# Load balancer services

There are 2 load balancer services:
- Streamer: for streaming from source to server
- WebRTC: for streaming from server to client

You can get their external IPs:
```bash
kl -n ome get svc
```

If you are behind NAT you need to set up port forwarding.

You can skip port forwarding for Streamer service if you don't want to stream from outside of LAN.

You can skip port forwarding for WebRTC if you don't plan on using WebRTC for watching video.

WebRTC forwarded ports must match ports of the service itself and configuration of OME server
(clients get advertisement for ports based on server configuration).

WebRTC determines host IP automatically, and clients try to connect to it.
If your service IP does not match the IP that the server can detect using "show my IP" external services,
you need to set `OME_WEBRTC_CANDIDATE_IP` environment variable to point to correct IP.

# How to stream

- [optional] Set up local DNS to point to `provide_ip`
- Set up OBS
- - Go to `Settings -> Stream`
- - Set server: `rtmp://<provide_ip or DNS>:1935/app`
- - Set stream key: an arbitrary string
- - `/app` corresponds to `<Name>app</Name>` in `ome-config.xml`, and can be changed by editing the config.
- - Reference: [OME quickstart docs](https://airensoft.gitbook.io/ovenmediaengine/quick-start)

You can see several `streamer` services depending on your setup.
Just `streamer` will connect to a random available OME origin instance.
`streamer-<something>` will connect to instance with certain capabilities.

# SRT streaming

You need to change stream URL in OBS:

- Generic: `srt://{domain:port}/?streamid=srt://{domain:port}/{app}/{stream_key}&latency={microseconds}`
- `domain:port` can be omitted: `srt://{domain:port}/?streamid=srt://0/{app}/{stream_key}&latency={microseconds}`
- For example: `srt://10.0.2.4:9999/?streamid=srt://0/tc/danil&latency=15000`

# Playback

- Deploy [OvenPlayer](../ovenplayer/readme.md)
- Create stream link that corresponds to your config and OBS settings

# Playback with WebRTC (sub-second latency)

- Streaming via HTTPS: `wss://<ingress_public_domain>/app/<stream-key>`
- It's possible to stream via HTTP by connecting to `svc/viewer` directly
or if your ingress doesn't enforce HTTPS
but config in this folder doesn't allow this.
You will need to modify the config if you want to use plain HTTP.
- `/app` and `<stream-key>` must match OSB settings
- WebSockets forbid mixed content.
- - If you open OvenPlayer via HTTPS Ingress,
    plain HTTP playback will not work, and vice versa.
- Make sure to [setup port forwarding](#load-balancer-services)

# LLHLS playback (latency 1-3 seconds)

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

# Build CUDA image

```bash
docker_username=
docker_repo=

docker build https://github.com/AirenSoft/OvenMediaEngine/raw/4b297cc97fbc8e9ff76d71bf08a0394d90723a49/Dockerfile.cuda \
    --build-arg OME_VERSION=v0.16.4 \
    -t docker.io/$docker_username/$docker_repo:ome-official-v0.16.4-fixed
docker push docker.io/$docker_username/$docker_repo:ome-official-v0.16.4-fixed
```

# TODO

https://github.com/AirenSoft/OvenMediaEngine/discussions/1609
