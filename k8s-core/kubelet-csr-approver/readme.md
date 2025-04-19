
# kubelet-csr-approver

This app can automatically verify and approve CertificateSigningRequests inside cluster.

This is required to run `metrics-server`.

References:
- https://github.com/postfinance/kubelet-csr-approver

# Generate config

You only need to do this if you change `values.yaml` file.

```bash
helm repo add kubelet-csr-approver https://postfinance.github.io/kubelet-csr-approver
helm repo update kubelet-csr-approver
helm search repo kubelet-csr-approver/kubelet-csr-approver --versions --devel | head
helm show values kubelet-csr-approver/kubelet-csr-approver > ./k8s-core/kubelet-csr-approver/default-values.yaml
```

```bash

helm template \
  csr-approver \
  kubelet-csr-approver/kubelet-csr-approver \
  --version 1.0.7 \
  --values ./k8s-core/kubelet-csr-approver/values.yaml \
  --namespace csr-approver \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/instance:|d' -e '\|app.kubernetes.io/version|d' \
  > ./k8s-core/kubelet-csr-approver/deployment.gen.yaml

```

# Init local settings

```bash

mkdir -p ./k8s-core/kubelet-csr-approver/env
 cat << EOF > ./k8s-core/kubelet-csr-approver/env/rules.env
# set to true if your node names don't resolve as valid DNS names
BYPASS_DNS_RESOLUTION=false
# pattern for allowed node names
PROVIDER_REGEX=.*\.k8s\.lan$
# allowed node IPs
# you probably want to set this to your LAN CIDR
# set to 0.0.0.0/0,::/0 to disable this check
PROVIDER_IP_PREFIXES=10.0.0.0/24
EOF

```

# Deploy

You need to make sure `serverTLSBootstrap` is enabled in kubelet config before deploying this.

```bash

kl create ns csr-approver
kl apply -k ./k8s-core/kubelet-csr-approver/
kl -n csr-approver get pod -o wide

# check CSRs to make sure they are approved
kl get csr

```

# Cleanup

```bash
kl delete -k ./k8s-core/kubelet-csr-approver/
kl delete ns csr-approver
```

# Manual approval

```bash
kl certificate approve <csr-name>
```

# More docs

References:
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#kubelet-serving-certs
- https://github.com/kubernetes-sigs/metrics-server/blob/master/FAQ.md#how-to-run-metrics-server-securely
- https://github.com/kubernetes-sigs/metrics-server#requirements
- https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/
- https://github.com/kubernetes-sigs/metrics-server/issues/196

# Check CSR content

References:
- https://www.base64decode.org
- https://www.sslshopper.com/csr-decoder.html
- https://certlogik.com/decoder/
