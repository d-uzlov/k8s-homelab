
# Deploy

```bash
kl create ns iperf3

kl apply -f ./test/iperf3/iperf3.yaml
kl apply -f ./test/iperf3/iperf3-client.yaml

kl -n iperf3 get pod -o wide

# check connection speed between pods
kl -n iperf3 exec deployments/iperf3-client -it -- iperf3 -c iperf3
kl -n iperf3 exec deployments/iperf3-client -it -- iperf3 -c iperf3-lb

# check connection speed to outside network
# replace ip with ip of your iperf server
kl -n iperf3 exec deployments/iperf3-client -it -- iperf3 -c 10.3.10.3

# check connection speed from LAN to cluster
# - via nodeport service
nodePort=$(kl -n iperf3 get svc iperf3-lb -o go-template --template "{{ (index .spec.ports 0).nodePort}}")
nodeName=$(kl -n iperf3 get pod -l app=iperf3 -o go-template --template "{{ (index .items 0).spec.nodeName}}")
nodeIp=$(kl get node $nodeName -o go-template --template "{{ (index .status.addresses 0).address}}")
iperf3 -c $nodeIp -p $nodePort
# - via loadbalancer
kl apply -k ./test/iperf3/loadbalancer/
kl -n iperf3 get svc iperf3-lb
lbip=$(kl -n iperf3 get svc iperf3-lb -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
iperf3 -c $lbip
iperf3 -c $lbip --reverse
iperf3 -c $lbip --bidir
```

# Cleanup

```bash
kl delete -k ./test/iperf3/loadbalancer/
kl delete -f ./test/iperf3/iperf3.yaml
kl delete -f ./test/iperf3/iperf3-client.yaml
kl delete ns iperf3
```

# Results

- Cilium
- - Pod-to-pod via native: `18.9 Gbit/s`
- - Pod-to-pod via geneve: `1 Gbit/s`, `1.5 Gbit/s`
- - Pod-to-pod via native + wireguard: `1 Gbit/s`
- - Pod-to-pod via geneve + wireguard: `1 Gbit/s`
- - Node port external access: `16.9 Gbit/s`, `17.5 Gbit/s`
