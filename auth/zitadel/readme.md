
# Zitadel

Current version seems to have a memory leak.

References:
- https://github.com/zitadel/zitadel
- https://zitadel.com/docs/self-hosting/deploy/compose

# Deploy

```bash

kl create ns zitadel
kl label ns zitadel pod-security.kubernetes.io/enforce=baseline

kl apply -k ./auth/zitadel/init/
kl -n zitadel get pod -o wide
kl -n zitadel logs jobs/init
kl -n zitadel wait --for condition=complete job/init --timeout=30s
kl -n zitadel describe job init
kl -n zitadel delete job init

kl apply -k ./auth/zitadel/httproute-private/
kl -n zitadel get httproute
kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}"

kl apply -k ./auth/zitadel/setup/
kl -n zitadel get pod -o wide
kl -n zitadel logs jobs/setup
kl -n zitadel wait --for condition=complete job/setup --timeout=30s
kl -n zitadel describe job setup
kl -n zitadel delete job setup

kl apply -k ./auth/zitadel/
kl -n zitadel get pod -o wide
kl -n zitadel logs deployments/zitadel

# go here to set up access
echo "https://"$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/if/flow/initial-setup/
# print default user login
echo "zitadel-admin@zitadel.$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")"
# default password is Password1!

# after you finished the initial set up process, it's safe to open public access to zitadel
kl apply -k ./auth/zitadel/httproute-public/
kl -n zitadel get httproute

# zitadel has single issuer URL for all projects/apps
# print issuer URL
echo https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")
# print discovery URL
echo https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration
curl https://$(kl -n zitadel get httproute zitadel-private -o go-template --template "{{ (index .spec.hostnames 0)}}")/.well-known/openid-configuration | jq

```

Don't forget to enable `Projects -> your_project -> your_application -> Grant Types -> Refresh Token`.

# Cleanup

```bash
kl -n zitadel delete job init
kl -n zitadel delete job setup
kl delete -k ./auth/zitadel/
kl delete -k ./auth/zitadel/postgres-cnpg/
kl delete ns zitadel
```

# Debugging

```bash

# if you are getting Errors.IAM.NotFound
# check the list of active domains in the database
kl cnpg -n zitadel psql cnpg app << EOF
SELECT * FROM eventstore.fields
WHERE object_type = 'instance_domain'
AND field_name = 'domain';
EOF

```
