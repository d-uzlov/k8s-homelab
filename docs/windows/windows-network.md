
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
- Set metric manually, where 1 is the highest priority and 9999 is the lowest

# Show routes

```powershell
netstat -r
route print
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

# VLANs

References:
- https://taeffner.net/2022/04/multiple-vlans-windows-10-11-onboard-tools-hyper-v/
- https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines?tabs=powershell

```powershell
# find NetAdapterName (first column)
Get-NetAdapter

New-VMSwitch -name VLAN-vSwitch -NetAdapterName "Ethernet 5" -AllowManagementOS $true
# in case something goes wrong you can simply delete vSwitch to undo changes
Remove-VMSwitch VLAN-vSwitch

# remove native VLAN port in case you don't need it
# skip it if you are using native VLAN
Remove-VMNetworkAdapter -ManagementOS -Name VLAN-vSwitch

# name can be arbitrary, we only use vlan prefix for convenience
Add-VMNetworkAdapter -ManagementOS -Name VLAN2-storage -SwitchName VLAN-vSwitch -Passthru
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName VLAN2-storage -Access -VlanId 2

Add-VMNetworkAdapter -ManagementOS -Name VLAN3-k8s -SwitchName VLAN-vSwitch -Passthru
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName VLAN3-k8s -Access -VlanId 3

Add-VMNetworkAdapter -ManagementOS -Name VLAN5-guest -SwitchName VLAN-vSwitch -Passthru
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName VLAN5-guest -Access -VlanId 5

# check results
Get-NetAdapter
```

In automatic setup I encountered MTU issues preventing anything from working.

In native connection `ping 10.0.0.1 -l 1462` was working fine.
In hyper-v vSwitch setup at most `ping 10.0.0.1 -l 1458` worked.

I found 2 solutions:
- Set `Encapsulation overhead` on the parent interface to at least 32 (the lowest possible value aside from 0)
- Increate MTU on the parent interface

# MTU

```powershell
# you can get interface name here:
netsh interface ipv4 show subinterface
netsh interface ipv4 set interface "interface-name" mtu=1280
```
