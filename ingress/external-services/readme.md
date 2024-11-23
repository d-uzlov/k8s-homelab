
# Exposing external services via ingress

You can use k8s ingress of gateway to expose
some service that isn't hosted inside k8s.

Generate yaml from template and customize it to your needs.

```bash
mkdir -p ./ingress/external-services/env/

# human-readable dns-compatible name
service_name=
# ip or domain
service_address=
target_port=80
httproute_domain=
ingress_domain=
ingress_secret=
sed \
  -e "s/service_name/$service_name/" \
  -e "s/service_address/$service_address/" \
  -e "s/target_port/$target_port/" \
  -e "s/httproute_domain/$httproute_domain/" \
  -e "s/ingress_domain/$ingress_domain/" \
  -e "s/ingress_secret/$ingress_secret/" \
  ./ingress/external-services/template.yaml \
  > ./ingress/external-services/env/$service_name.yaml

namespace=default
kl -n $namespace apply -f ./ingress/external-services/env/$service_name.yaml
```
