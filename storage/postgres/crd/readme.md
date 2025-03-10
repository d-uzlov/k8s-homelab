
```bash

(cd ./storage/postgres/crd/ &&
rm -f ./*.crd.yaml
wget https://github.com/zalando/postgres-operator/raw/v1.14.0/manifests/operatorconfiguration.crd.yaml &&
wget https://github.com/zalando/postgres-operator/raw/v1.14.0/manifests/postgresql.crd.yaml &&
wget https://github.com/zalando/postgres-operator/raw/v1.14.0/manifests/postgresteam.crd.yaml &&
echo done
)

```
