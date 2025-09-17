
# Helm

# Install

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

References:
- https://helm.sh/docs/intro/install/
- https://github.com/helm/helm/releases

# Example of using template

```bash
helm repo add repo-name https://name.repo.com/charts
helm repo update repo-name
helm search repo repo-name/chart-name --versions --devel | head
# get version from `search repo`
# create your own values.yaml based on default-values.yaml
helm show values repo-name/chart-name --version 1.2.3 > ./path/to/chart-name/default-values.yaml
```

```bash

helm template --no-hooks \
  --include-crds \
  app-name \
  repo-name/chart-name \
  --version 1.2.3 \
  --namespace app-name \
  --values ./path/to/chart-name/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' -e '\|app.kubernetes.io/version|d' \
  > ./path/to/chart-name/app-name.gen.yaml

```

Helm does not give you a way to get CRDs out of the chart.
`helm install` will just replace your existing CRDs with CRDs from the chart.
`helm template` omits CRDs by default.
`helm template --include-crds` includes all chart CRDs into the list of resources, which makes it unmanageable.

Your best bet is downloading CRDs manually from the developer github.
