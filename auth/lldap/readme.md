
# lldap

References
- https://github.com/lldap/lldap
- https://hub.docker.com/r/lldap/lldap/tags

# config

```bash

mkdir -p ./auth/lldap/env/

 cat << EOF > ./auth/lldap/env/lldap-config.env
jwt_secret=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
key_seed=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
admin_pass=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

```

# deploy

```bash

kl create ns auth-lldap
kl label ns auth-lldap pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/lldap/
kl -n auth-lldap get pod

kl apply -k ./auth/lldap/httproute-protected/
kl -n auth-lldap get htr

```

# cleanup

```bash
kl delete -k ./auth/lldap/httproute-protected/
kl delete -k ./auth/lldap/
# don't forget to delete all postgres objects BEFORE deleting the namespace
# to avoid namespace deletion getting stuck
kl delete ns auth-lldap
```
