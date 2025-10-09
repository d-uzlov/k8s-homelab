
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
client_secret=

# test that connection parameters are correct
# if your auth provider supports device code grant, it's more convenient to use it
kl oidc-login setup --oidc-issuer-url $issuer_url --oidc-client-id $client_id --oidc-extra-scope offline_access --skip-open-browser
kl oidc-login setup --oidc-issuer-url $issuer_url --oidc-client-id $client_id --oidc-extra-scope offline_access --skip-open-browser --grant-type device-code
# in case your provider uses setup for confidential client, add client secret param
kl oidc-login setup --oidc-issuer-url $issuer_url --oidc-client-id $client_id --oidc-extra-scope offline_access --skip-open-browser --grant-type device-code --oidc-client-secret $client_secret

# `oidc-login setup` will print out commands to alter your current kubeconfig.
# Alternatively, you can alter it manually.
# Add a new user to `users` section:

cat << EOF
- name: REPLACE_ME_USERNAME
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      args:
      - oidc-login
      - get-token
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

You will also need to add context that will use this new user (adjust actual values for your config):

```yaml
- context:
    cluster: example
    user: oidc
  name: oidc@example
```

Note that even after you set up authentication (user is verified by the cluster),
you will most likely need additional authorization setup (user is allowed to do things).

See example how you can set up authorization specific to a single user.
As an alternative, you can use group for permissions, but it's not covered here [yet].

```bash

# auth whoami is available without any special authorization
kl auth whoami

user_context=oidc@example
user_id=$(kl --context $user_context auth whoami -o json | jq .status.userInfo.username -r)
echo $user_id

admin_context=admin@example
kl --context $admin_context create clusterrolebinding "oidc-cluster-admin:$user_id" --clusterrole cluster-admin --user "$user_id"

# kl delete clusterrolebinding "oidc-cluster-admin:$user_id"

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
