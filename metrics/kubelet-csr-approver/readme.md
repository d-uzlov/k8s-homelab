
# kubelet-csr-approver

https://github.com/postfinance/kubelet-csr-approver

This app can automatically verify and approce SertificateSigningReuqests inside cluster.

This is required to run `metrics-server`.

# Deploy

You need to make sure `serverTLSBootstrap` is enabled in kubelet config before deploying this.

```bash
# Init local settings
mkdir -p ./metrics/kubelet-csr-approver/env
cat <<EOF > ./metrics/kubelet-csr-approver/env/rules.env
# limit allowed node names
PROVIDER_REGEX=.*
# limit allowed node IPs
PROVIDER_IP_PREFIXES=0.0.0.0/0,::/0
# set to true if your node names don't resolve as valid DNS names
BYPASS_DNS_RESOLUTION=true
EOF

kl create ns csr-approver
kl apply -k ./metrics/kubelet-csr-approver

# check CSRs to make sure they are aproved
kl get csr
```
