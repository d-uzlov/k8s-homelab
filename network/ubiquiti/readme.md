

- Set up `Settings > System > Advanced > Inform Host`.
- Set up local DNS for `unify` address to point to unify controller.


# Run temporary controller locally

Just for testing.

You can inject the config into k8s later.

```bash
docker run \
  --name=unifi-controller \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 8443:8443 \
  -p 3478:3478/udp \
  -p 10001:10001/udp \
  -p 8080:8080 \
  -v /tmp/unify-config:/config \
  lscr.io/linuxserver/unifi-controller:7.4.162
```
