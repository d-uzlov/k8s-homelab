
# Apiserver configuration for OIDC

You need to customize your auth config manually.
Use example as a starting point.

```bash

mkdir -p ./k8s-core/docs/env/
# use example config as a reference,
# customize it for your environment
cp ./k8s-core/docs/auth-config-example.yaml ./k8s-core/docs/env/auth-config.yaml

```

Documentation about file configuration:
https://kubernetes.io/docs/reference/access-authn-authz/authentication/#using-authentication-configuration

# Copy config to master nodes

Make sure that your k8s apiserver has `authentication-config=/etc/k8s-auth/auth-config.yaml` option.

```bash

# run for each master node
cp_node1=
ssh $cp_node1 sudo tee '>' /dev/null /etc/k8s-auth/auth-config.yaml < ./k8s-core/docs/env/auth-config.yaml

```

When configured properly (see example [cluster config](./kubeadm-config/cluster.yaml)),
apiserver will watch changes and apply updated config automatically.

Sometimes config is invalid.
Check apiserver logs to see if auth config was applied successfully.
Entry `reloaded authentication config` means successful config reload.

# OIDC login in kubectl

Before running this, create OIDC application.
Make sure that `offline_access` claim is allowed,
or you will need to manually re-authenticate when initial token expires.

```bash

kl krew install oidc-login
kl krew upgrade oidc-login

# use base issuer URL, without /.well-known/... part
issuer_url=https://auth.example.com/token/
client_id=
# optional, only set when provider requires it
client_secret=6583367cc16b0f7d3fb8d9671048f53ad1eaee4c

# test that connection parameters are correct
kl oidc-login setup --oidc-issuer-url $issuer_url --oidc-client-id $client_id --oidc-extra-scope offline_access --skip-open-browser --grant-type device-code
# in case your provider uses setup for confidential client, add client secret param
kl oidc-login setup --oidc-issuer-url $issuer_url --oidc-client-id $client_id --oidc-extra-scope offline_access --skip-open-browser --grant-type device-code --oidc-client-secret $client_secret

# `oidc-login setup` will print out commands to alter your current kubeconfig.
# Alternatively, you can alter it manually.
# Add a new user to `users` section:

# this username is only for the client side
username=oidc

cat << EOF
- name: $username
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      args:
      - oidc-login
      - get-token
      # - -v=8
      - --grant-type=device-code
      - --oidc-issuer-url=$issuer_url
      - --oidc-client-id=$client_id
      - --skip-open-browser
      - --oidc-extra-scope=offline_access
      command: kubectl
      env: null
      interactiveMode: Never
      provideClusterInfo: false
EOF

```

Note that even after you set up authentication (user is verified by the cluster),
you will most likely need additional authorization setup (user is allowed to do things):

```bash

# user id will depend on your cluster auth setup
user_id=
kl create clusterrolebinding oidc-cluster-admin --clusterrole cluster-admin --user 'user_id'

```

# Check current token contents:

```bash

ll ~/.kube/cache/oidc-login/
# choose one of the files

# if you didn't use rust before, install cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install jwt-cli

jq .id_token -r ~/.kube/cache/oidc-login/2a873c56504aaa8ba00a4f6dfcc252dde71566fc68a648175bd71b685b5949d4 | jwt decode -

```

# Test requesting token manually

```bash

# =========== public clients (without client secret) ===========

issuer_url=https://auth.example.com/token/
client_id=

discovery_info=$(curl -sS $issuer_url/.well-known/openid-configuration)
device_endpoint=$(echo $discovery_info | jq .device_authorization_endpoint -r)
token_endpoint=$(echo $discovery_info | jq .token_endpoint -r)

# request device node token
request_info=$(curl -sS --data-urlencode client_id=$client_id --data-urlencode "scope=offline_access openid" -X POST $device_endpoint)
# some applications provide verification_uri_complete, some require user to manually type user_code at verification_uri page, and some provide the complete value in verification_uri
echo $request_info | jq
# open the supplied link and confirm the access
# after access is granted, obtain access token and refresh token
device_code=$(echo $request_info | jq .device_code -r)
token=$(curl -sS --data-urlencode client_id=${client_id} --data-urlencode client_secret=$client_secret --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:device_code --data-urlencode device_code=$device_code -X POST $token_endpoint)
echo $token | jq
# extract refresh token
refresh_token=$(echo $token | jq .refresh_token -r)
# try to refresh access token
curl -sS --data-urlencode client_id=$client_id --data-urlencode grant_type=refresh_token --data-urlencode refresh_token=$refresh_token --data-urlencode "scope=offline_access openid" -X POST $token_endpoint | jq

# =========== confidential clients (using client secret) ===========

issuer_url=https://auth.example.com/token/
client_id=
client_secret=

discovery_info=$(curl -sS $issuer_url/.well-known/openid-configuration)
device_endpoint=$(echo $discovery_info | jq .device_authorization_endpoint -r)
token_endpoint=$(echo $discovery_info | jq .token_endpoint -r)

request_info=$(curl -sS -u "$client_id:$client_secret" --data-urlencode "scope=offline_access openid" -X POST $device_endpoint)
echo $request_info | jq
device_code=$(echo $request_info | jq .device_code -r)
token=$(curl -sS -u "$client_id:$client_secret" --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:device_code --data-urlencode device_code=$device_code -X POST $token_endpoint)
echo $token | jq
refresh_token=$(echo $token | jq .refresh_token -r)
curl -sS -u "$client_id:$client_secret" --data-urlencode grant_type=refresh_token --data-urlencode refresh_token=$refresh_token --data-urlencode "scope=offline_access openid" -X POST $token_endpoint | jq

```
