
# Deploy

```bash
kl create ns ingress-test
kl label ns ingress-test pod-security.kubernetes.io/enforce=baseline
kl -n ingress-test apply -f ./network/default-network-policies.yaml
kl apply -f ./test/ingress/network-policy.yaml

# choose one of:
# deploy echo server
kl apply -f ./test/ingress/echo.yaml
# deploy echo server for control plane
kl apply -f ./test/ingress/echo-cp.yaml
# deploy daemonset
kl apply -f ./test/ingress/echo-ds.yaml

kl -n ingress-test get pod -o wide

# depoy different ingress resources
kl label ns --overwrite ingress-test copy-wild-cert=main
kl apply -f ./test/ingress/service.yaml
kl apply -k ./test/ingress/wildcard/
kl apply -k ./test/ingress/http01/
kl -n ingress-test get ingress

# check out if HSTS is enabled
# (this repo uses settings to disable it)
# If you see something like this, HSTS is enabled:
#   strict-transport-security: max-age=15724800; includeSubDomains
test_domain=$(kl -n ingress-test get ingress echo-wildcard -o go-template --template "{{ (index .spec.rules 0).host}}")
curl "https://$test_domain/" && ! curl -s -D- "https://$test_domain/" | grep strict-transport-security

# deploy load balancer service
kl apply -k ./test/ingress/loadbalancer/
# check loadbalancer
kl -n ingress-test get svc echo-lb-cluster echo-lb-local
curl $(kl -n ingress-test get svc echo-lb-cluster -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
curl $(kl -n ingress-test get svc echo-lb-local -o go-template --template "{{ (index .status.loadBalancer.ingress 0).ip}}")
kl -n ingress-test logs deployments/echo

kl apply -k ./test/ingress/httproute/
kl -n ingress-test get httproute echo
kl -n ingress-test describe httproute echo

test_domain=$(kl -n ingress-test get httproute echo -o go-template --template "{{ (index .spec.hostnames 0) }}")
curl -v "$test_domain"
curl "https://$test_domain/" && ! curl -s -D- "https://$test_domain/" | grep strict-transport-security
```

# Cleanup

```bash
kl delete -k ./test/ingress/httproute/
kl delete -k ./test/ingress/wildcard
kl delete -k ./test/ingress/http01/
kl delete -k ./test/ingress/loadbalancer/

kl delete -f ./test/ingress/echo.yaml
kl delete -f ./test/ingress/echo-cp.yaml
kl delete -f ./test/ingress/echo-ds.yaml

kl delete ns ingress-test
```
