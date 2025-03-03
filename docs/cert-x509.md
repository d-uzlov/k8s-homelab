
# x509 Certificates

# Generate a cert for CA

```bash

# name can ba anything, it does not matter for CA
ca_name=
ca_path=./docs/backup/env/$ca_name-ca

# create new private key for CA
openssl genpkey -algorithm ED25519 -out $ca_path.key
# RSA keys are at the same time both longer and less secure than ED25519
# openssl genpkey -algorithm RSA -out $ca_path-2.key

# self-signed cert for CA
openssl req -x509 -new -days 3650 -subj "/CN=$ca_name" -key $ca_path.key -out $ca_path.crt
openssl x509 -in $ca_path.crt -noout -text

# arguments:
# -new: new CSR
# -x509: don't output CSR, generate and output certificate instead
# -key (without -in, without -CA): create self-signed certificate with given key

```

# subj format

Format: `/ID1=value/ID2=value/ID3=value`.
Add as many IDs as needed.

Common IDs:
- `CN` - Common Name
- `O` - Organization name

List of other commonly used IDs: https://www.ibm.com/docs/en/ibm-mq/7.5?topic=certificates-distinguished-names

# Generate client certificates, sign using CA

```bash

client_name=
client_group=
client_path=./docs/backup/env/$client_group-$client_name

# client private key
openssl genpkey -algorithm ED25519 -out $client_path.key

# create CSR
# even if you don't need alt names, you usually need to set CN as alt name
# you can add more than one alt name if needed:
# -addext "subjectAltName = DNS:example.com,DNS:*.example.com,IP:10.0.0.1"

openssl req -new -subj "/CN=$client_name/O=$client_group" \
  -out $client_path.csr \
  -key $client_path.key \
  -addext "extendedKeyUsage = serverAuth, clientAuth" \
  -addext "subjectAltName = DNS:$client_name"

# arguments:
# -new: new CSR

# sign CSR using CA
openssl x509 -req -in $client_path.csr \
  -CA $ca_path.crt \
  -CAkey $ca_path.key \
  -CAcreateserial \
  -out $client_path.crt \
  -copy_extensions copy \
  -days 3650

openssl x509 -in $client_path.crt -noout -text

# arguments:
# -req: expect CSR as input
# -copy_extensions copy: copy non-critical extensions
#                        By default subjectAltName and extendedKeyUsage will be stripped

```

References:
- https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl
- https://arminreiter.com/2022/01/create-your-own-certificate-authority-ca-using-openssl/
- https://blog.pinterjann.is/ed25519-certificates.html

# Check certificate file info

```bash
# show key info (public and private)
openssl pkey -in file.key -noout -text
# show key info (public only)
openssl pkey -in file.key -noout -text_pub

# show CSR info
openssl req -in file.csr -noout -text

# show certificate info
openssl x509 -in file.crt -noout -text

```
