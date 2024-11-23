
# Netbird

References:
- https://app.netbird.io/
- https://hub.docker.com/r/netbirdio/netbird/tags

# Service install

```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sh
setup_key=
netbird login --setup-key $setup_key
netbird up
netbird status -d
```

Don't forget to approve the new peer in the netbird web console.

# Docker install

```bash
setup_key=
docker run --network host --privileged --rm -d --name netbird -v ./netbird-client:/etc/netbird netbirdio/netbird:0.31.0 --setup-key $setup_key
docker ps
docker logs netbird
docker exec -it netbird sh

# status doesn't work in docker with netbird 0.31
docker exec netbird netbird status -d
```

# iptables setup

If you want to create netbird gateway from LAN
without setting up two-way routing,
you need to enable NAT in the gateway,
so packets from remote netbird host can return to the gateway LAN.

```bash
for t in filter nat mangle raw security; do
   echo "table $t:"
   sudo iptables -t $t -S -v
done

cat /etc/iproute2/rt_tables
ip r s t all

sudo iptables -t nat -A POSTROUTING -o wt0 -j MASQUERADE
# in case you want more granularity:
# sudo iptables -t nat -A POSTROUTING -o wt0 -j MASQUERADE --source IP/mast --destination IP/mask
# sudo iptables -t nat -A POSTROUTING -o wt0 -j MASQUERADE -m iprange --src-range IP-IP --dst-range IP-IP

# check current setup
sudo iptables -t nat -C POSTROUTING -o wt0 -j MASQUERADE
sudo iptables -t nat -L POSTROUTING
sudo iptables -t nat -S POSTROUTING
# delete
sudo iptables -t nat -D POSTROUTING -o wt0 -j MASQUERADE

# to avoid redoing this on startup
sudo apt install iptables-persistent
# edit persistent iptables' rules
sudo nano /etc/iptables/rules.v4
```
