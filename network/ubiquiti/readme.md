
# unifi controller

References:
- https://hub.docker.com/r/linuxserver/unifi-controller
- https://hub.docker.com/r/linuxserver/unifi-network-application

# L3 adoption

When unifi controller is not in the same L2 network,
devices will not be able to find it automatically.

You can set up local DNS to point `unifi` address to address of the controller.

You can also set up `Settings > System > Advanced > Inform Host`
in the controller settings to change advertised address, in case you don't want to use `unifi`.
However, if you connect a new device, or reset current device settings,
the device will not know the new address until it is connected,
which means you will still need to use `unifi` address for initial connection.

References:
- https://help.ui.com/hc/en-us/articles/204909754-UniFi-Device-Adoption-Methods-for-Remote-UniFi-Controllers

# SSH adoption

- `ssh ubnt@10.0.1.0`
- - Replace IP with your value
- - default password is `ubnt`
- Run: `set-inform http://unifi:8080/inform`
- - here `unifi` is a DNS record that points to the controller
- - replace it with another appropriate record or with IP address
- Go to controller web-ui -> `System Log` -> `<name> is ready for adoption. Click to adopt it`

You can use `unifi.ubiquiti.kubelb.lan` instead of `unifi`
if you have deployed the [DNS k8s gateway](../../ingress/dns-k8s-gateway/readme.md).

For example: `set-inform http://unifi.ubiquiti.kubelb.lan:8080/inform`.

# Deploy

```bash
kl create ns ubiquiti
kl label ns ubiquiti pod-security.kubernetes.io/enforce=baseline

# kl -n ubiquiti apply -f ./network/network-policies/deny-ingress.yaml
# kl -n ubiquiti apply -f ./network/network-policies/allow-same-namespace.yaml
# kl -n ubiquiti apply -f ./network/network-policies/allow-lan.yaml

kl apply -k ./network/ubiquiti/loadbalancer/
kl -n ubiquiti get svc

kl label ns --overwrite ubiquiti copy-wild-cert=main
kl apply -k ./network/ubiquiti/ingress-wildcard/
kl -n ubiquiti get ingress

kl apply -k ./network/ubiquiti/pvc/
kl -n ubiquiti get pvc

kl apply -k ./network/ubiquiti/
kl -n ubiquiti get pod -o wide
```

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
