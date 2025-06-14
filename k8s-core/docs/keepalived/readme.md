
References:
- https://github.com/shawly/docker-keepalived
- Archived but useful as a reference: https://github.com/bsctl/kubelived
- https://www.keepalived.org/manpage.html

```bash

# random number in range [1, 255]
virtual_router_id=
# example for: 10.3.0.255/16
# interface is selected automatically based on matching prefix
virtual_ip=10.3.0.255
virtual_prefix=16

node=
 ssh $node sudo tee /etc/kubernetes/manifests/keepalived.yaml << EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: keepalived-$node
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: keepalived
    image: ghcr.io/shawly/keepalived:2.3.1
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_BROADCAST
    resources:
      requests:
        memory: 10Mi
        cpu: 10m
      limits:
        memory: 50Mi
    env:
    - name: KEEPALIVED_VIRTUAL_IP
      value: $virtual_ip
    - name: KEEPALIVED_VIRTUAL_MASK
      value: '$virtual_prefix'
    - name: KEEPALIVED_VRID
      value: '$virtual_router_id'
    - name: KEEPALIVED_CHECK_SCRIPT
      value: \/usr\/bin\/curl -s -k https:\/\/localhost:6443\/healthz -o \/dev\/null
EOF

```
