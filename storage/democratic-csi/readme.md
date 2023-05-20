
# source

https://github.com/democratic-csi/democratic-csi

Somewhat of a guide:
https://github.com/fenio/k8s-truenas

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update
helm search repo democratic-csi/
```

```bash
# Init local settings
cat <<EOF > ./storage/democratic-csi/passwords.env
host=truenas.example
username=democratic-csi
password=password
EOF

helm template \
    --values ./storage/democratic-csi/iscsi.yaml \
    iscsi democratic-csi/democratic-csi \
    > ./storage/democratic-csi/iscsi-deployment.gen.yaml

(. ./storage/democratic-csi/env/passwords.env &&
sed \
    -e "s|REPLACE_ME_HOST|$host|g" \
    -e "s|REPLACE_ME_USERNAME|$username|g" \
    -e "s|REPLACE_ME_PASSWORD|$password|g" \
    ./storage/democratic-csi/iscsi-config.template.yaml
) > ./storage/democratic-csi/env/iscsi-config.yaml

kl create ns pv-democratic-csi
kl apply -k ./storage/democratic-csi/
```

На truenas:
Создать аккаунт
Задать пароль (по идее можно без него, но у меня не получилось)
Выставить `Allow all sudo commands with no password`
Снять `Allow all sudo commands`
Вход через webui работает, если выставить следующие группы:
`builtin_administrators,builtin_users,admin,root,wheel`
Вероятно, часть групп можно убрать.

# Переиспользование PV

Поставить storage class Retain

После удаление PVC удалить claimRef.uid e PV

kubectl patch pv <pv name> -p '{"spec":{"claimRef":{"uid": null}}}'
