
# Reset DHCP lease

```bash
sudo dhclient -r; sudo dhclient
```

# Show DNS information

```bash
cat /etc/resolv.conf
resolvectl
```

# Show open ports

```bash
apt install net-tools
netstat -tuplen
```
