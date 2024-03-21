
# Set up management network

If you don't disable default gateway on a secondary network,
windows will try to balance access to internet between 2 networks.

It works this way because windows assigns
roughly equal metrics to routes from default gateways.

This will cause issues if one of the networks doesn't have internet access.

To fix this:
- Open `Control Panel\Network and Internet\Network Connections`
- Open interface properties
- Go to IPv4 settings
- Click Advanced
- Uncheck `Automatic metric`
- Set metric manually, where 0 is the highest priority

# Show routes

```powershell
netstat -r
```

# Show full network config

```powershell
ipconfig /all
```

# Flush DNS cache

```powershell
ipconfig /flushdns
```

# Reset DHCP lease

```powershell
# renew connects to previously used DHCP server
ipconfig /renew

# release resets fully DHCP config
# if your DHCP server changed, call release+renew
ipconfig /release
ipconfig /renew
```

# ARP cache

```powershell
# show current ARP cache
arp -a
# reset APR cache
arp -d *
```
