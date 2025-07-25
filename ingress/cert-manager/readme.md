
# Cert-manager

This is an app to automatically create and update certificates
by automatically issuing them from any ACME-compatible certificate provider.

References:
- https://github.com/cert-manager/cert-manager

# Generate config

You only need to do this when updating the app.

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm search repo jetstack/cert-manager --versions --devel | head
helm show values jetstack/cert-manager --version v1.17.1 > ./ingress/cert-manager/default-values.yaml
```

```bash

helm template \
  cert-manager jetstack/cert-manager \
  --values ./ingress/cert-manager/values.yaml \
  --version v1.17.1 \
  --namespace cert-manager \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by: Helm|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/cert-manager/cert-manager.gen.yaml

wget https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml \
  -O ./ingress/cert-manager/cert-manager.crds.yaml

```

# Deploy

```bash

mkdir -p ./ingress/cert-manager/env/
clusterName=
 cat << EOF > ./ingress/cert-manager/env/patch-cluster-tag.yaml
- op: add
  path: /spec/staticConfigs/0/labels/cluster
  value: $clusterName
EOF

kl apply -f ./ingress/cert-manager/cert-manager.crds.yaml --server-side

kl create ns cert-manager
kl label ns cert-manager pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/cert-manager/
kl -n cert-manager get pod -o wide

kl -n cert-manager get cert
kl -n cert-manager get issuer
kl get clusterissuer cluster-ca

```

# Cleanup

```bash

kl delete -k ./ingress/cert-manager/
kl delete ns cert-manager
kl delete -f ./ingress/cert-manager/cert-manager.crds.yaml

```

# Manual metric checking

```bash

kl -n cert-manager describe svc cm
kl -n cert-manager describe svc cm-cainjector
kl -n cert-manager describe svc cm-webhook

kl exec deployments/alpine -- apk add curl
kl exec deployments/alpine -- curl -sS http://cm.cert-manager:9402/metrics > ./cm-metrics.log
# metrics from other components seem useless
kl exec deployments/alpine -- curl -sS http://cm-cainjector.cert-manager:9402/metrics > ./cm-cainjector-metrics.log
kl exec deployments/alpine -- curl -sS http://cm-webhook.cert-manager:9402/metrics > ./cm-webhook-metrics.log

```

# Deploy issuers

Choose what you need:

- HTTP-01 (universal, does not depend on DNS provider)
- - [LetsEncrypt](./letsencrypt/readme.md)
- DNS-01
- - [DuckDNS](./duckdns/readme.md)
- - [acme-dns](./acme-dns/readme.md)

# Ingress with automatic certificates

Cert-manager supports automatic certificate injection for ingress resources.
A separate certificate will be created for each resource.

- Add an annotation (choose one depending on your issuer type)
- - `cert-manager.io/cluster-issuer: issuer-name`
- - `cert-manager.io/issuer: issuer-name`
- Set `spec.tls.0.secretName`
- [Optional] Adjust `spec.tls.0.hosts` array, in case the domain is not detected automatically

# Ingress with manual certificate

If you have a secret with a domain certificate, you can use it in ingress.

You can create a secret by uploading it manually,
or by creating a `Certificate` resource in the target namespace.

You can also copy a secret from another namespace, to use a shared certificate
(this is the recommended approach for wildcard certificates).

- Create a secret
- - For example, here is a [shared "main" certificate](../manual-certificates/readme.md)
- - The "main" certificate also has instructions for Replicator
- Deploy [Replicator](../replicator/readme.md)
- Mark target namespace with appropriate label
- Set `spec.tls.0.secretName` to a name of the copied secret

# Error handling

Ingress creates a new certificate if requested certificate currently doesn't exist.
Certificates are kept as a k8s secrets.

If you create a certificate with incorrect settings,
then change the settings, but keep the secret name the same,
it will not be automatically reissued with new settings.
You need to either change the secret name or delete the old secret.

# Browser error handling

If you have opened the web page with a wrong certificate, the certificate may be cached.
Even if you update the certificate on the server side, the client won't see it.

You need to clear browser cache to pick up the new certificate.
You may also need to restart the browser after clearing the cache.
