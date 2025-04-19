
# Apiserver configuration for OIDC

You need to customize your auth config manually.
Use example as a starting point.

```bash

mkdir -p ./k8s-core/docs/env/
cp ./k8s-core/docs/auth-config-example.yaml ./k8s-core/docs/env/auth-config.yaml

```

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
Make sure that it has `offline_access` claim access.

```bash

kl krew install oidc-login

# use base issuer URL, without /.well-known/ part
issuer_url=https://auth.example.com/application/o/app/
client_id=

# test that connection parameters are correct
kl oidc-login setup --oidc-issuer-url=$issuer_url --oidc-client-id=$client_id --oidc-extra-scope=offline_access --skip-open-browser --grant-type=device-code

# `oidc-login setup` will print out commands to alter your current kubeconfig.
# Alternatively, you can alter it manually.
# Add a new user to `users` section:

# this username is only for client side
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
you may need additional authorization setup (user is allowed to do things):

```bash

# user id will depend on your cluster auth setup
user_id=
kl create clusterrolebinding oidc-cluster-admin --clusterrole cluster-admin --user 'user_id'

```

You may want to check current token contents:

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

issuer_url=https://auth.example.com/application/o/app/
client_id=

# request device node token
curl -d "client_id=qwe123&scope=offline_access+openid" -X POST $issuer_url/oauth/v2/device_authorization
# open the supplied link and confirm the access
# after access is granted, obtain access token and refresh token
curl -d "client_id=qwe123&device_code=QhQ4uY6xyXMKvWtnb0aZ8g&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code" -X POST $issuer_url/oauth/v2/token
# extract refresh token
refresh_token=
# try to refresh access token
curl -d "client_id=qwe123&grant_type=refresh_token&refresh_token=$refresh_token&scope=offline_access+openid" -X POST $issuer_url/oauth/v2/token

```
