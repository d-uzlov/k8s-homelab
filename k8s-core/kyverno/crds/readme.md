
# Download new CRDs

The list of CRDs is manually grabbed from the release files

```bash

(
set -e
rm -f ./k8s-core/kyverno/crds/*kyverno.io_* ./k8s-core/kyverno/crds/wgpolicyk8s.io_*
cd ./k8s-core/kyverno/crds/
version=v1.15.2
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_cleanuppolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_clustercleanuppolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_clusterpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_globalcontextentries.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_policies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_policyexceptions.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/kyverno.io_updaterequests.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_deletingpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_generatingpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_imagevalidatingpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_mutatingpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_policyexceptions.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/policies.kyverno.io_validatingpolicies.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/reports.kyverno.io_clusterephemeralreports.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/reports.kyverno.io_ephemeralreports.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/wgpolicyk8s.io_clusterpolicyreports.yaml
wget https://github.com/kyverno/kyverno/releases/download/$version/wgpolicyk8s.io_policyreports.yaml
)

```
