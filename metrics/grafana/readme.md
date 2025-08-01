

# Grafana

References:
- https://github.com/grafana/grafana
- https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/


# Generate config

You only need to do this if you change `values.yaml` file.

```bash

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
helm search repo grafana/grafana --versions --devel | head
helm show values grafana/grafana --version 9.3.0 > ./metrics/grafana/default-values.yaml

helm template \
  grafana \
  grafana/grafana \
  --version 9.3.0 \
  --values ./metrics/grafana/values.yaml \
  --namespace grafana \
  | sed \
    -e '\|helm.sh/chart|d' \
    -e '\|# Source:|d' \
    -e '\|app.kubernetes.io/managed-by:|d' \
    -e '\|app.kubernetes.io/instance:|d' \
    -e '\|app.kubernetes.io/version|d' \
    -e '\|app.kubernetes.io/part-of|d' \
    -e '/^ *$/d' \
    -e '\|httpHeaders\:$|d' \
  > ./metrics/grafana/grafana.gen.yaml

```

# Prerequisites

Grafana will work just fine on its own.

But for it to be useful you need to deploy dashboards to actually see data.

For dashboards to work, you need to deploy
prometheus and related scrape configurations.

- [prometheus](../kube-prometheus-stack/readme.md)
- [kube-state-metrics](../kube-state-metrics/readme.md)
- [node-exporter](../node-exporter/readme.md)

# Deploy

```bash

mkdir -p ./metrics/grafana/env/

clusterName=
 cat << EOF > ./metrics/grafana/env/patch-cluster-tag.yaml
- op: add
  path: /spec/endpoints/0/relabelings/0
  value:
    targetLabel: cluster
    replacement: $clusterName
    action: replace
EOF

 cat << EOF > ./metrics/grafana/env/admin.env
username=admin
password=$(LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
EOF
grafana_public_domain=
 [ -f ./metrics/grafana/env/grafana.ini ] || cat << EOF > ./metrics/grafana/env/grafana.ini
[analytics]
check_for_updates = true
[grafana_net]
url = https://grafana.net
[log]
mode = console
[paths]
data = /var/lib/grafana/
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning
[server]
root_url = https://$grafana_public_domain/
EOF

kl create ns grafana
kl label ns grafana pod-security.kubernetes.io/enforce=baseline

kl apply -k ./metrics/grafana/
kl -n grafana get pod -o wide

kl apply -k ./metrics/grafana/httproute-private/
kl apply -k ./metrics/grafana/httproute-public/
kl -n grafana get httproute
kl -n grafana describe httproute grafana-private
kl -n grafana describe httproute grafana-public

kl label ns --overwrite grafana copy-wild-cert=main
kl apply -k ./metrics/kube-prometheus-stack/grafana-ingress-wildcard/
kl -n grafana get ingress

```

# Cleanup

```bash
kl delete -k ./metrics/grafana/httproute-public/
kl delete -k ./metrics/grafana/httproute/
kl delete -k ./metrics/grafana/
kl delete ns grafana
```

# Automatic provisioning

Grafana automatically imports data from configmaps with certain labels:

- Datasources: label `grafana.com/datasource: main`
- Dashboards: label `grafana.com/dashboard: main`

Only the own `grafana` namespace is monitored.

# Manual metric checking

```bash
kl exec deployments/alpine -- curl -sS http://grafana.grafana/metrics
```

# Authentik SSO

Prerequisites:
- [Authentik](../../auth/authentik/readme.md)

References:
- https://docs.goauthentik.io/integrations/services/grafana/

In authentik:

- Create provider of type OAuth2/OpenID
- Add `Redirect URIs/Origins` domains (change `grafana-public.example.com` to your ingress domain):
- - https://grafana-public.example.com/login/generic_oauth
- Create `grafana` application linked to this provider
- Fill in grafana config using info on the `grafana` provider page

```ini
[auth]
; this would cause all logout actions to redirect to authentik, even when using native auth
; signout_redirect_url = https://authentik.example.com/application/o/grafana/end-session/
; docs: https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#signout_redirect_url
; docs: https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/generic-oauth/#configuration-options
[auth.generic_oauth]
enabled = true
allow_sign_up = true
auto_login = false
; team_ids =
; allowed_organizations =
name = authentik
scopes = openid profile email
; ↓ copy from provider details in authentik ui ↓
; you probably just need to replace authentik.example.com with your domain
client_id = To0JjdhF6pmqNCY1QCvR0xzDYAHsJUWlygPsunZa
client_secret = qooWV3ENvHq7ydTDHa2qVsXqEjDgALxaI71R6hZ2ZcfjbdaLhtZulcqFQ9sZ7rhQMtHm6vjmrUYKP3DmPcDwMRIT2OOhesjdVptUMEu5E1FoCLk2TkXYjuEodImoUsSM
auth_url =             https://authentik.example.com/application/o/authorize/
token_url =            https://authentik.example.com/application/o/token/
api_url =              https://authentik.example.com/application/o/userinfo/
signout_redirect_url = https://authentik.example.com/application/o/grafana/end-session/
; ↑ copy from provider details in authentik ui ↑
use_pkce = true
use_refresh_token = true
role_attribute_path: contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || contains(groups, 'Grafana Viewers') && 'Viewer'
; deny login if user is not in some grafana group
role_attribute_strict: true
```

Append the config to `./env/grafana.ini`.
Redeploy grafana after changing the config.

You will not be able to log into Grafana with a generic authentik user.
Set one of the groups for the user first (configurable via `role_attribute_path`):

- `Grafana Admins`
- `Grafana Editors`
- `Grafana Viewers`

# Disable annoying loading animation

Add the following CSS patch in any CSS patcher for your browser:

```css
/* hide loading animation above each of the panels */
.panel-loading { display: none !important; }
.css-ol7v04-panel-loading-bar-container { display: none !important; }

/* hide loading animation near variable name */
/* 11.5.1 */
.css-1dx36ai * {
  display: none;
}
/* 11.6.1 */
.css-10cklh6 * {
  display: none;
}
```

You may need to adjust this when Grafana is updated.
It seems like Grafana generates CSS classes with random names.

Example extensions:
- https://chromewebstore.google.com/detail/custom-css-by-denis/cemphncflepgmgfhcdegkbkekifodacd?hl=en
- https://chromewebstore.google.com/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne?hl=en
- https://chromewebstore.google.com/detail/stylish-custom-themes-for/fjnbnpbmkenffdnngjfgmeleoegfcffe?hl=en&pli=1
