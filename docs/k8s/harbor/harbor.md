
# Harbor

Harbor can be used as a registry mirror / proxy.

# Prerequisites

Create VM or container.

```bash
# node address
harbor_node=root@harbor1.k8s.lan
ssh $harbor_node apt update
ssh $harbor_node apt full-upgrade -y
ssh $harbor_node apt install curl wget
ssh $harbor_node curl -fsSL https://get.docker.com -o get-docker.sh
ssh $harbor_node sh get-docker.sh
```

# Generate certificates

References:
- https://goharbor.io/docs/2.10.0/install-config/configure-https/

```bash
# common address to be used for client access
harbor_address=harbor.k8s.lan
# node addresses (a lot of addresses for future proofing)
harbor_address1=harbor1.k8s.lan
harbor_address2=harbor2.k8s.lan
harbor_address3=harbor3.k8s.lan
harbor_address4=harbor4.k8s.lan
harbor_address5=harbor5.k8s.lan
harbor_address6=harbor6.k8s.lan

mkdir -p ./docs/k8s/harbor/env/

# generate Certificate Authority
openssl genrsa -out ./docs/k8s/harbor/env/ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=CN/O=local-harbor/OU=Personal/CN=$harbor_address" \
  -key ./docs/k8s/harbor/env/ca.key \
  -out ./docs/k8s/harbor/env/ca.crt

# Generate and sign the server certificate
openssl genrsa -out ./docs/k8s/harbor/env/domain.key 4096
openssl req -sha512 -new \
  -subj "/C=CN/O=local-harbor/OU=Personal/CN=$harbor_address" \
  -key ./docs/k8s/harbor/env/domain.key \
  -out ./docs/k8s/harbor/env/domain.csr

cat > ./docs/k8s/harbor/env/v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1=$harbor_address1
DNS.2=$harbor_address2
DNS.3=$harbor_address3
DNS.4=$harbor_address4
DNS.5=$harbor_address5
DNS.6=$harbor_address6
DNS.7=$harbor_address
EOF

openssl x509 -req -sha512 -days 3650 \
  -extfile ./docs/k8s/harbor/env/v3.ext \
  -CA ./docs/k8s/harbor/env/ca.crt \
  -CAkey ./docs/k8s/harbor/env/ca.key \
  -CAcreateserial \
  -in ./docs/k8s/harbor/env/domain.csr \
  -out ./docs/k8s/harbor/env/domain.crt
```

# Install Harbor

References:
- https://goharbor.io/docs/2.10.0/install-config/download-installer/

```bash
harbor_node=root@harbor1.k8s.lan
harbor_version=v2.10.1
ssh $harbor_node wget https://github.com/goharbor/harbor/releases/download/$harbor_version/harbor-online-installer-$harbor_version.tgz
ssh $harbor_node tar xzvf harbor-online-installer-$harbor_version.tgz

ssh $harbor_node mkdir -p /harbor-data/cert/
scp ./docs/k8s/harbor/env/domain.key ./docs/k8s/harbor/env/domain.crt $harbor_node:/harbor-data/cert/

# download the default config for reference
ssh $harbor_node cat ./harbor/harbor.yml.tmpl > ./docs/k8s/harbor/env/harbor.yml.tmpl

harbor_password=
sed -e "s/REPLACE_ME_HOSTNAME/$harbor_address/" \
  -e "s|REPLACE_ME_CERTIFICATE_CRT|/harbor-data/cert/domain.crt|" \
  -e "s|REPLACE_ME_CERTIFICATE_KAY|/harbor-data/cert/domain.key|" \
  -e "s|REPLACE_ME_PASSWORD|$harbor_password|" \
  ./docs/k8s/harbor/config-template.yaml |
  ssh $harbor_node cat '>' ./harbor/harbor.yml
ssh $harbor_node ./harbor/install.sh

# create a systemd service to handle node restarts
# see here: https://github.com/lamw/harbor-appliance/issues/6
ssh $harbor_node tee /etc/systemd/system/harbor.service < ./docs/k8s/harbor/harbor.service
ssh $harbor_node systemctl daemon-reload
ssh $harbor_node systemctl enable harbor
ssh $harbor_node systemctl restart harbor
```

- Now you can go to `harbor_address` or any of `harbor_addressN` and log in.
- Default user name is: `admin`
- Password is: set via `harbor_password`

# Setup Harbor as a proxy

1. `Administration -> Registries -> New Endpoint`, create endpoints for all registries you are interested in
2. `Projects -> New Project`, switch on `Proxy Cache`, select the endpoint

This readme assumes that proxy registry names will match addresses used by images:

- Docker Hub: `docker.io`
- GitHub: `ghcr.io`
- Quay: `quay.io`
- K8s registry: `registry.k8s.io`
- - Use generic "Docker registry" endpoint type

You can also add `gcr.io` as a "Docker registry" but there doesn't seems to be any useful images there.

Endpoint names don't matter.

References:
- https://goharbor.io/docs/2.10.0/install-config/harbor-compatibility-list/
- https://goharbor.io/docs/2.10.0/administration/configure-proxy-cache/

# Garbage collection

Increase or decrease the default garbage collection timeout for unused tags:
`Projects -> Project -> Policy -> Retention rules -> Action -> Edit`.

The default is 7 days.
