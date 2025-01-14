
# Authentik

Authentik is an identity provider.
It can be used to do unified auth across many applications.
It can also be used as a proxy, adding auth to simple applications that don't have it on its own.

References:
- https://goauthentik.io/#comparison
- https://xpufx.com/posts/protecting-your-first-app-with-authentik/
- https://medium.com/@wessel__/istio-with-authentik-securing-your-cluster-and-providing-authentication-and-authorization-b5e48b331920

# Generate config

You only need to do this when updating the app.

```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update authentik
helm search repo authentik/authentik --versions --devel | head
helm show values authentik/authentik --version 2024.12.1 > ./ingress/authentik/default-values.yaml
```

```bash
# https://hub.docker.com/r/bitnamicharts/redis/tags
helm show values oci://registry-1.docker.io/bitnamicharts/redis --version 20.6.2 > ./ingress/authentik/redis-default-values.yaml

helm template \
  authentik \
  authentik/authentik \
  --version 2024.12.1 \
  --namespace authentik \
  --values ./ingress/authentik/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./ingress/authentik/authentik.gen.yaml

helm template \
  redis \
  oci://registry-1.docker.io/bitnamicharts/redis \
  --version 20.6.2 \
  --namespace authentik \
  --values ./ingress/authentik/db/redis-values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' -e 's/redis-data/data/' \
  > ./ingress/authentik/db/redis.gen.yaml

```

# Deploy

Generate passwords and set up config.

```bash
mkdir -p ./ingress/authentik/db/env/
cat << EOF > ./ingress/authentik/db/env/redis-password.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
cat << EOF > ./ingress/authentik/db/env/redis-sc.env
# authentik keeps session info in redis, so we need PVC for to avoid resetting sessions on restart
redis_storage_class=nvmeof
EOF
cat << EOF > ./ingress/authentik/db/env/postgres-sc.env
postgres_storage_class=nvmeof
EOF

mkdir -p ./ingress/authentik/env/
cat << EOF > ./ingress/authentik/env/authentik-seed.env
# Secret key used for cookie signing. Changing this will invalidate active sessions.
# Prior to 2023.6.0 the secret key was also used for unique user IDs.
# When running a pre-2023.6.0 version of authentik the key should not be changed after the first install.
authentik_seed=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF

# consult your email provider for info how to connect to smtp
# if you don't want to use it, leave everything empty
# for example:
# - yandex: https://yandex.ru/support/yandex-360/customers/mail/ru/mail-clients/others.html#smtpsetting
# - google: https://support.google.com/a/answer/176600?hl=en
cat << EOF > ./ingress/authentik/env/authentik-smtp.env
auth_smtp_host=AUTOREPLACE_SMTP_HOST
auth_smtp_port=AUTOREPLACE_SMTP_PORT
auth_smtp_username=AUTOREPLACE_SMTP_USERNAME
auth_smtp_password=AUTOREPLACE_SMTP_PASSWORD
auth_smtp_use_tls=false
auth_smtp_use_ssl=true
# example: "Authentik <user@example.com>"
auth_smtp_from="AUTOREPLACE_SMTP_FROM"
EOF

```

```bash

kl create ns authentik
kl label ns authentik pod-security.kubernetes.io/enforce=baseline

kl apply -k ./ingress/authentik/db/
kl -n authentik get pvc
kl -n authentik get pod -o wide -L spilo-role

authentik_seed=$(. ./ingress/authentik/env/authentik-seed.env; echo $authentik_seed)
redis_password=$(. ingress/authentik/db/env/redis-password.env; echo $redis_password)
postgres_password=$(kl -n authentik get secret authentik.postgres.credentials.postgresql.acid.zalan.do --template='{{.data.password | base64decode | printf "%s\n" }}')
cat << EOF > ./ingress/authentik/env/authentik-passwords-patch.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: authentik
stringData:
  AUTHENTIK_POSTGRESQL__PASSWORD: $postgres_password
  AUTHENTIK_REDIS__PASSWORD: $redis_password
  AUTHENTIK_SECRET_KEY: $authentik_seed
EOF
( . ./ingress/authentik/env/authentik-smtp.env;
cat << EOF > ./ingress/authentik/env/authentik-smtp-patch.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: authentik
stringData:
  AUTHENTIK_EMAIL__FROM: $auth_smtp_from
  AUTHENTIK_EMAIL__HOST: $auth_smtp_host
  AUTHENTIK_EMAIL__PASSWORD: $auth_smtp_password
  AUTHENTIK_EMAIL__PORT: '$auth_smtp_port'
  AUTHENTIK_EMAIL__USE_SSL: '$auth_smtp_use_ssl'
  AUTHENTIK_EMAIL__USE_TLS: '$auth_smtp_use_tls'
  AUTHENTIK_EMAIL__USERNAME: $auth_smtp_username
EOF
)

kl apply -k ./ingress/authentik/
kl -n authentik get pod -o wide -L spilo-role

kl apply -k ./ingress/authentik/httproute-private/
kl -n authentik get httproute

# go here to set up access
echo "https://"$(kl -n authentik get httproute authentik -o go-template --template "{{ (index .spec.hostnames 0)}}")/if/flow/initial-setup/
# after you finished the initial set up process, it's safe to open public access to authentik
kl apply -k ./ingress/authentik/httproute-public/
kl -n authentik get httproute

```

# Cleanup

```bash
kl delete -k ./ingress/authentik/
kl delete ns authentik
```

# Authentik logout doesn't affect application cookies

References:
- https://github.com/goauthentik/authentik/issues/2023

# Set dark theme by default

> In admin panel, open the last settings of one of these items
> - Brand settings
> - Group settings
> - User settings
> Add:
> ```yaml
> settings:
> theme:
>   base: dark
> ```

References:
- https://github.com/goauthentik/authentik/discussions/7016#discussioncomment-10374755

# Fix password managers

- Go to `Admin Interface -> Flows and Stages -> Flows`
- Edit `default-authentication-flow`: `Behavior settings -> Compatibility mode +`
- Repeat for any other flows that you may need

References:
- https://github.com/goauthentik/authentik/discussions/2419

# email settings

**Note**: there is a regression in 2024.12 which prevents you
from sending emails and generating recover links as admin.
- https://github.com/goauthentik/authentik/issues/12445

You can bypass this by removing the `Authentication` requirement from the `default-recovery-flow`.

---

References:
- https://docs.goauthentik.io/docs/troubleshooting/emails

```bash
# test sending an email
# set address that should receive test email from authentik
address=example@.example.com
kl -n authentik exec -it deployment/authentik-worker -c worker -- ak test_email $address
```

It seems like version 2024.12.1 doesn't have a recovery flow by default.
You can download one from authentik documentation:
`Add and Secure Applications -> Flows and Stages -> Flows -> Defaults and Examples -> Example flows`:
https://docs.goauthentik.io/docs/add-secure-apps/flows-stages/flow/examples/flows

In case documentation has changed, you can find a January 2025 copy of the recovery flow here:
[flows-recovery-email-verification.yaml](./flows-recovery-email-verification-408d6afeff2fbf276bf43a949e332ef6.yaml).

Import and enable this flow in authentik settings:
-  `Admin interface -> Flows and Stages -> Flows -> Import`
-  `Admin interface -> System -> Brands -> authentik-default -> Edit -> Default Flows -> Recovery flow`

You can customize email appearance:
-  `Admin interface -> Flows and Stages -> Flows -> (click on name) default-recovery-flow -> Stage Bindings -> default-recovery-email -> Edit Stage`

# Enrollment (creating account)

I didn't do this.
This link is here because the official documentation seems to be lackluster.

References:
- https://www.youtube.com/watch?v=mGOTpRfulfQ

# Istio setup (for proxy auth)

1. Add new outpost with name `public`: `Admin interface -> Applications -> Outposts`

Open advanced settings, set `authentik_host` to the public domain
where authentik will be available from the internet.

Enable the k8s integration.

2. Add authentik extension into istio config:

```bash

mkdir -p ./ingress/istio/mesh-config/env/
cat << EOF > ./ingress/istio/mesh-config/env/extension-authentik.yaml
- name: authentik
  envoyExtAuthzHttp:
    service: ak-outpost-public.authentik.svc.cluster.local
    port: "9000"
    pathPrefix: /outpost.goauthentik.io/auth/envoy
    headersToDownstreamOnAllow:
    - cookie
    headersToUpstreamOnAllow:
    - set-cookie
    - x-authentik-*
    # Add authorization headers to the allow list if you need proxy providers which
    # send a custom HTTP-Basic Authentication header based on values from authentik
    # - authorization
    includeRequestHeadersInCheck:
    - cookie
EOF

```

Then redeploy istio to pick up new config:
- [istio](../istio/readme.md#deploy)

# Application setup (for proxy auth)

Application can delegate auth to OAuth provider, like authentik, google, etc.
This is NOT what this block is about.
Here we only set up proxy auth: protecting access to the application that doesn't support it natively.

1. Deploy Istio's `AuthorizationPolicy` object with `spec.provider.name = authentik`
and list all domains that you want to be protected by proxy auth.

```yaml
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  # suggestion: use `namespace.httproute_name` naming scheme to avoid name collisions
  name: namespace.route
  # when auth policy is in the root namespace (where istiod is located) it is applied to the whole cluster
  # namespace: istio
  # when auth policy is in custom namespace, it only applies to this namespace
  namespace: gateways
spec:
  selector:
    matchLabels:
      gateway.istio.io/managed: istio.io-gateway-controller
  action: CUSTOM
  provider:
    name: authentik
  rules:
  - to:
    - operation:
        hosts:
        - example.com
```

References:
- https://istio.io/latest/docs/reference/config/security/authorization-policy/

Policy above will enable auth for `example.com` domain.

2. Go to  authentik web UI and create required resources:

- Create provider: `Admin interface -> Applications -> Providers`
- - `Forward auth (single application)`: create separate proxy for each app
- - `Forward auth (domain level)`: create one shared proxy. Note that access permissions are also shared.
- Create application: `Admin interface -> Applications -> Applications`
- [optional] Set up application permission: `Admin interface -> Applications -> Applications -> "YourApp" -> Policy/Group/User bindings`
- - When there are no bindings, every registered user can access the app
- - When app has _any_ bindings, user must succeed policy check to access the app
- Bind app to outpost (=listener): `Admin interface -> Applications -> Outposts -> public -> Edit (button on the right) -> Add app into the list`
