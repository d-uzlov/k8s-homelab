
# OPNSense

References:
- https://opnsense.org

# Logs

You can enable firewall logs in `Firewall -> Settings -> Advanced -> Logging`.
Beware that these logs can consume a lot of space. Even if have a big dis, you can run out of space.

You can limit the size of these logs here: `System -> Settings -> Logging -> Maximum file size`.

# Useful plugins

- `os-iperf`
- `os-ntopng`
- `os-qemu-guest-agent `
- `os-redis`
- `os-theme-cicada`

# Enable SSH

- Create new user: System -> Access
- Enable SSH: System -> Settings -> Administration -> Secure Shell
- Enable `sudo`: System -> Settings -> Administration -> Authentication -> Sudo

# Install utils

- `opnsense-code tools ports src`
- `cd /usr/ports/sysutils/htop && sudo make install`
- `cd /usr/ports/sysutils/lscpu && sudo make install`

References:
- HTOP process viewer install: https://forum.opnsense.org/index.php?topic=7796.0

# Enable NAT loopback

- Firewall > Settings -> Advanced -> Automatic outbound NAT for Reflection

Reference:
- https://forum.opnsense.org/index.php?topic=34925.0

# Disable mitigations

- System -> Settings -> Tunables
- `vm.pmap.pti=0`
- `hw.ibrs_disable=1`

References:
- System hardening vs performance: https://docs.opnsense.org/troubleshooting/hardening.html

# CPU load diagnostics

- System -> Diagnostics -> Activity

# Set up DNS over TLS

- Services -> Unbound DNS -> DNS over TLS
- Fill in the list of known DNS servers

References:
- https://docs.opnsense.org/manual/unbound.html
- - You can find a list of well-known DoT servers there

# Bridge (connect) several interfaces

- Interfaces -> Other Types -> Bridge -> Add
- Add all interfaces except currently active one
- Set tunables (important!)
- - `net.link.bridge.pfil_member=0`
- - `net.link.bridge.pfil_bridge=1`
- Assign active interface to bridge
- Move physical cable from old active interface to bridged one
- Add previously active interface to bridge

This can be simplified a bit if you have a second network,
and don't care about keeping connection for configuring settings.

References:
- https://docs.opnsense.org/manual/how-tos/lan_bridge.html

# Force DNS to local

Optional, but can be helpful.

- Firewall > NAT > Port Forward
- LAN, TCP/UDP, dest ! LAN net, target 127.0.0.1
- References:
- - Unbound DNS: https://docs.opnsense.org/manual/unbound.html
- - Redirect Unencrypted DNS Requests to Your Local DNS Resolver: https://homenetworkguy.com/how-to/redirect-all-dns-requests-to-local-dns-resolver/
- - Redirect all DNS Requests to Opnsense: https://forum.opnsense.org/index.php?topic=9245.0
