
# LLDAP

References:
- https://github.com/lldap/lldap?tab=readme-ov-file#with-kubernetes
- https://github.com/Evantage-WS/lldap-kubernetes

# Deploy

```bash

mkdir -p ./auth/lldap/env/

cat << EOF > ./auth/lldap/env/config.env
LLDAP_JWT_SECRET=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 64)
LLDAP_LDAP_USER_PASS=admin
LLDAP_BASE_DN=dc=evantage,dc=nl
EOF

```
