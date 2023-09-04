
# source

https://github.com/democratic-csi/democratic-csi

Somewhat of a guide:
https://github.com/fenio/k8s-truenas

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update
helm search repo democratic-csi/democratic-csi --versions | head
```

```bash
# re-generate deployment config if needed
helm template \
  iscsi democratic-csi/democratic-csi \
  --version 0.14.1 \
  --values ./storage/democratic-csi/iscsi-truenas-scale/values.yaml \
  --set nameOverride=dcsi \
  --set fullnameOverride=dcsi \
  --namespace pv-dcsi \
  > ./storage/democratic-csi/iscsi-truenas-scale/deployment.gen.yaml

# Init local settings
cat <<EOF > ./storage/democratic-csi/iscsi-truenas-scale/env/passwords.env
host=truenas.lan
username=democratic-csi
password=password
EOF
cat <<EOF > ./storage/democratic-csi/iscsi-truenas-scale/env/iscsi.env
main_dataset=ssd/k8s/block
snapshot_dataset=ssd/k8s/block-snap
EOF

(. ./storage/democratic-csi/iscsi-truenas-scale/env/passwords.env &&
. ./storage/democratic-csi/iscsi-truenas-scale/env/iscsi.env &&
sed \
  -e "s|REPLACE_ME_HOST|$host|g" \
  -e "s|REPLACE_ME_USERNAME|$username|g" \
  -e "s|REPLACE_ME_PASSWORD|$password|g" \
  -e "s|REPLACE_ME_MAIN_DATASET|$main_dataset|g" \
  -e "s|REPLACE_ME_SNAP_DATASET|$snapshot_dataset|g" \
  ./storage/democratic-csi/config.template.yaml
) > ./storage/democratic-csi/env/config.yaml

kl create ns pv-dcsi
kl apply -k ./storage/democratic-csi/iscsi-truenas-scale/
```

# Truenas setup

- Create account
- Set password for the account
- - I didn't manage to make it work with an ssh key, without a password.
- - This is likely because it needs to be able to access web UI.
- Set `Allow all sudo commands with no password`
- Clear `Allow all sudo commands`
- Set up account groups to allow web-ui login
- - `builtin_administrators,builtin_users,admin,root,wheel`
- - Maybe only some of the groups are needed

# Reuse PVs

Set storage class `reclaimPolicy` to `Retain`.

After you delete PVC edit the PV and clear `claimRef.uid`.
For example:
```bash
kubectl patch pv pv_name -p '{"spec":{"claimRef":{"uid": null}}}'
```
