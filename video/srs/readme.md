
# SRS: Simple Realtime Server

References:
- https://github.com/ossrs/srs

# Helm

```bash
helm repo add srs http://helm.ossrs.io/stable
helm repo update srs
helm search repo srs/srs-server --versions --devel | head
helm show values srs/srs-server --version 1.0.5 > ./video/srs/default-values.yaml
```

```bash

helm template \
  srs \
  srs/srs-server \
  --version 1.0.5 \
  --values ./video/srs/values.yaml \
  --namespace srs \
  | sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '/^ *$/d' \
  > ./video/srs/srs.gen.yaml

```

# Deploy

```bash

kl create ns srs
kl label ns srs pod-security.kubernetes.io/enforce=baseline

kl apply -k ./video/srs/
kl -n srs get pod -o wide
kl -n srs get svc

kl apply -k ./video/srs/htr-api-private/
kl apply -k ./video/srs/htr-web-public/
kl -n srs get htr

docker run --rm -it ossrs/srs:encoder ffmpeg -stream_loop -1 -re -i doc/source.flv -c copy -f flv rtmp://10.3.6.17/live/livestream

```

rtmp://10.3.6.17/live/livestream

To use WHIP for streaming: http://10.3.6.17:1985/rtc/v1/whip/?app=live&stream=livestream
To use WHIP for streaming: http://10.3.131.157:1985/rtc/v1/whip/?app=live&stream=livestream
To use WHEP for playback: http://10.3.6.17:1985/rtc/v1/whep/?app=live&stream=livestream
To use WHEP for playback: https://srs.meoe.cloudns.be/rtc/v1/whep/?app=live&stream=livestream
To use WHEP for playback: https://srs-web-public.meoe.cloudns.be/rtc/v1/whep/?app=live&stream=livestream

Play stream by:

RTMP (by VLC): rtmp://10.3.6.17/live/livestream
H5(HTTP-FLV): http://10.3.6.17:8080/live/livestream.flv
H5(HLS): http://10.3.6.17:8080/live/livestream.m3u8

https://srs-web-public.meoe.cloudns.be/live/livestream.flv
https://srs-web-public.meoe.cloudns.be/live/livestream.m3u8

Stream URL
In SRS, both live streaming and WebRTC are based on the concept of streams. So, the URL definition for streams is very consistent. Here are some different stream addresses for various protocols in SRS, which you can access after installing SRS:

Publish or play stream over RTMP: rtmp://localhost/live/livestream
Play stream over HTTP-FLV: http://localhost:8080/live/livestream.flv
Play stream over HTTP-FLV: https://srs-web-public.meoe.cloudns.be/live/livestream.flv
Play stream over HLS: http://localhost:8080/live/livestream.m3u8
Play stream over HLS: https://srs-web-public.meoe.cloudns.be/live/livestream.m3u8
Publish stream over WHIP: http://localhost:1985/rtc/v1/whip/?app=live&stream=livestream
Play stream over WHEP: http://10.3.6.17:1985/rtc/v1/whep/?app=live&stream=livestream
Play stream over WHEP: https://srs-api-private.meoe.cloudns.be/rtc/v1/whep/?app=live&stream=livestream

curl https://srs-api-private.meoe.cloudns.be/api/v1/summaries | jq
curl https://srs-api-private.meoe.cloudns.be/api/v1/vhosts/ | jq
curl https://srs-api-private.meoe.cloudns.be/api/v1/vhosts/vid-f6g47x0 | jq
curl https://srs-api-private.meoe.cloudns.be/api/v1/clients/ | jq

 curl -v \
  -H "Content-Type: application/sdp" \
  --data-raw "v=0
a=group:BUNDLE 0 1
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=rtcp-mux
a=sendrecv
a=rtpmap:96 H264/90000" \
  http://10.3.6.17:1985/rtc/v1/whep/?app=live&stream=livestream
