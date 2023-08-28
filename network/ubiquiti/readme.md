
# L3 adoption

When unify controller is not in the same L2 network,
devices will not be able to find it automatically.

You can set up local DNS to point `unify` address to address of the controller.

You can also set up `Settings > System > Advanced > Inform Host`
in the controller settings to change advertised address, in case you don't want to use `unify`.
However, if you connect a new device, or reset current device settings,
the device will not know the new address until it is connected,
which means you will still need to use `unify` address for initial connection.

References:
- https://help.ui.com/hc/en-us/articles/204909754-UniFi-Device-Adoption-Methods-for-Remote-UniFi-Controllers

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
