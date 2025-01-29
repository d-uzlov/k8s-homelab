
# iptables

# ip route tables

This isn't really iptables, but this code feels comfortable in this file.

```bash
# list tables
cat /etc/iproute2/rt_tables
# show individual tables
ip route show table main
ip route show table local
# show all tables
ip route show table all
# or via short command
ip r s t all
```

# Show all tables

```bash
for t in filter nat mangle raw security; do
   echo "===== table $t: ====="
   sudo iptables -t $t -S -v
done
```

# Iptables chain diagram

References:
- https://unix.stackexchange.com/a/735420

```ascii
network  ->  PREROUTING  ->  routing  ->  INPUT  ------->  process
               raw           decision       mangle
               (conntrack)   |              filter
               mangle        |              security
               nat(*)        |              nat
                             V
                             FORWARD  ----\
                              mangle      |
                              filter      |
                              security    |
                                          V
process  ->  OUTPUT  ------------------>  POSTROUTING  ->  network
               (routing decision??)         mangle
               raw                          nat(*)
               (conntrack)
               mangle
               nat
               (output interface assigned here?)
               filter
               security

(*)  Certain localhost packets skip the PREROUTING and POSTROUTING nat
     chains.  See the post and diagram by Phil Hagen for details.
```

# iptables persistence

```bash

sudo apt install iptables-persistent
systemctl status --no-pager iptables

sudo netfilter-persistent save
# netfilter-persistent effectively does this:
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# check currently saved rules
sudo cat /etc/iptables/rules.v4

```
