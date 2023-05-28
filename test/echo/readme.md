
# Deploy

```bash
kl create ns echo
kl label ns echo copy-wild-cert=example

kl apply -k ./test/echo

curl -s https://echo.example.duckdns.org/ | grep client_address
curl -s $(kl -n echo get services echo -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}') | grep client_address

kl exec pods/curl -- ip a | grep "scope global eth0"
kl exec pods/curl -- curl -s echo.echo.svc | grep client_address
kl exec pods/curl -- curl -s https://echo.example.duckdns.org/ | grep client_address
kl exec pods/curl -- curl -s $(kl -n echo get services echo -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}') | grep client_address
```
