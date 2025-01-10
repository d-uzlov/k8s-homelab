
# Authentik

Authentik is an identity provider.
It can be used to do unified auth across many applications.
It can also be used as a proxy, adding auth to simple applications that don't have it on its own.

References:
- https://goauthentik.io/#comparison

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
cat <<EOF > ./ingress/authentik/db/env/redis-password.env
redis_password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
cat <<EOF > ./ingress/authentik/db/env/redis-sc.env
# authentik keeps session info in redis, so we need PVC for to avoid resetting sessions on restart
redis_storage_class=nvmeof
EOF
cat <<EOF > ./ingress/authentik/db/env/postgres-sc.env
postgres_storage_class=nvmeof
EOF

mkdir -p ./ingress/authentik/env/
cat <<EOF > ./ingress/authentik/env/authentik-seed.env
# Secret key used for cookie signing. Changing this will invalidate active sessions.
# Prior to 2023.6.0 the secret key was also used for unique user IDs.
# When running a pre-2023.6.0 version of authentik the key should not be changed after the first install.
authentik_seed=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
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

# Istio setup

1. Add new outpost with name `public`: `Admin interface -> Applications -> Outposts`

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

# Application setup

1. Deploy Istio's `AuthorizationPolicy` object with `spec.provider.name = authentik`
and list all domains that you want to have auth.

```yaml
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  # namespace.httproute_name to avoid name collisions in the gateways namespace
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
- - See other sections for more info on how to choose a provider
- Create application: `Admin interface -> Applications -> Applications`
- [optional] Set up application permission: `Admin interface -> Applications -> Applications -> "YourApp" -> Policy/Group/User bindings`
- - When there are no bindings, every registered user can access the app
- - When app has any bindings, user must succeed policy check to access the app
- Bind app to outpost (=listener): `Admin interface -> Applications -> Outposts -> public -> Edit (button on the right) -> Add app into the list`

# Provider: proxy

When application doesn't have its own auth, you can use proxy provider to guard access to the app.

You can create one provider per app. This way each app will use its own set of cookies.

You can create a single provider for parent domain, so they all will use single set of cookies.
This way you will only need to log in once.
However, you can no longer control app access separately. The whole parent domain counts as a single app.
If user have access to any subdomain, it will have access to all subdomains.
