
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
sudo apt install net-tools
sudo netstat -tuplen
```

# SSH port forwarding

```bash
ssh -L local_port:forwarded_ip:forwarded_port server-address

# for example, if the remote machine
# has access to an HTTP server in its LAN at address 192.168.1.1,
# you can use this to access it via localhost:8080
ssh -L 8080:192.168.1.1:80 server-address
```
