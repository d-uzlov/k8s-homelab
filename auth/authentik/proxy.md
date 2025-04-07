
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
