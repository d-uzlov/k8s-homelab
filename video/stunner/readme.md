
# Stunner

# Update

```bash
helm repo add stunner https://l7mp.io/stunner
helm repo update stunner
helm search repo stunner/stunner-gateway-operator --versions --devel | head
helm show values stunner/stunner-gateway-operator --version 0.21.0 > ./video/stunner/default-values.yaml
```

```bash
helm template \
  stunner \
  stunner/stunner-gateway-operator \
  --version 0.21.0 \
  --namespace stunner \
  --values ./video/stunner/values.yaml \
  > ./video/stunner/stunner.yaml

curl -fsSL "https://github.com/l7mp/stunner-helm/raw/refs/heads/main/helm/stunner-gateway-operator/crds/stunner-crd.yaml" > ./video/stunner/stunner-crd.yaml
```

# Deploy

```bash
kl apply -f ./video/stunner/stunner-crd.yaml --server-side

kl create ns stunner

kl apply -f ./video/stunner/stunner.yaml
kl -n stunner get pod -o wide

kl -n stunner apply -f ./video/stunner/gateway-class.yaml
kl get gatewayclass
# at this point gatewayclass status may be "unknown",
# until you deploy some gateway that uses it

kl create ns stunner-test
kl -n stunner-test apply -f ./video/stunner/gateway-test.yaml
kl -n stunner-test get gateway
kl -n stunner-test get svc

kl -n stunner-test apply -f ./video/stunner/udp-greeter.yaml
kl -n stunner-test get pod -o wide

go install github.com/l7mp/stunner/cmd/turncat@latest

turnIp=$(kl -n stunner-test get svc udp-test -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
testSvcIp=$(kl -n stunner-test get svc media-plane -o jsonpath='{.spec.clusterIP}') | turncat - turn://user-1:pass-1@$turnIp:3478 udp://${testSvcIp}:9001

kl delete ns stunner-test
```

# Cleanup

```bash
kl delete -f ./video/stunner/stunner.yaml
kl delete ns stunner
kl delete -f ./video/stunner/stunner-crd.yaml
```

