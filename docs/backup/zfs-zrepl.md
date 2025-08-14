
# zrepl

References:
- https://github.com/zrepl/zrepl
- https://github.com/dsh2dsh/zrepl

# Install

```bash

(
set -ex
zrepl_apt_key_url=https://zrepl.cschwarz.com/apt/apt-key.asc
zrepl_apt_key_dst=/usr/share/keyrings/zrepl.gpg
zrepl_apt_repo_file=/etc/apt/sources.list.d/zrepl.list

# Install dependencies for subsequent commands
sudo apt update && sudo apt install curl gnupg lsb-release

# Deploy the zrepl apt key.
curl -fsSL "$zrepl_apt_key_url" | tee | gpg --dearmor | sudo tee "$zrepl_apt_key_dst" > /dev/null

# Add the zrepl apt repo.
ARCH="$(dpkg --print-architecture)"
CODENAME="$(lsb_release -i -s | tr '[:upper:]' '[:lower:]') $(lsb_release -c -s | tr '[:upper:]' '[:lower:]')"
echo "Using Distro and Codename: $CODENAME"
echo "deb [arch=$ARCH signed-by=$zrepl_apt_key_dst] https://zrepl.cschwarz.com/apt/$CODENAME main" | sudo tee "$zrepl_apt_repo_file" > /dev/null
)

sudo apt-get update
sudo apt-get install zrepl

# see status and send signals
sudo zrepl status
# status will not work until you configure zrepl.yml
sudo nano /etc/zrepl/zrepl.yml

```

# Manual installation

```bash

wget https://github.com/zrepl/zrepl/releases/download/v0.6.1/zrepl-linux-amd64
mv ./zrepl-linux-amd64 zrepl
chmod +x ./zrepl

./zrepl configcheck --config ./zrepl-config/zrepl.yml
./zrepl --config ./zrepl-config/zrepl.yml

nohup sudo ./zrepl daemon --config ./zrepl-config/zrepl.yml > ./log-zrepl.log 2>&1 &

# if you want to run zrepl in background without user attention
sudo ./zrepl daemon --config ./zrepl-config/zrepl.yml > "./log-zrepl-$(/usr/bin/date +"%Y-%m-%dT%H-%M-%S%z").log" 2>&1

# see status and send signals
sudo ./zrepl status --config ./zrepl-config/zrepl.yml

```

# Node setup

Generate certificate for CA (once): [x509 Certificates](../cert-x509.md#generate-a-cert-for-ca)
See example values:

```bash
ca_name=
ca_path=./docs/backup/env/_.$ca_name-ca
```

Generate a certificate for each node: [x509 Certificates](../cert-x509.md#generate-client-certificates-sign-using-ca)
See example values:

```bash
node_hostname=
client_cert_name=$node_hostname.$ca_name
client_cert_group=
client_cert_path=./docs/backup/env/$client_cert_group#$client_cert_name
```

Send the certificate to node:

```bash

node_ssh_address=
ssh $node_ssh_address rm -rf ./zrepl-config/
ssh $node_ssh_address mkdir -p ./zrepl-config/
scp $ca_path.crt          $node_ssh_address:./zrepl-config/ca.crt
scp $client_cert_path.crt $node_ssh_address:./zrepl-config/node.crt
scp $client_cert_path.key $node_ssh_address:./zrepl-config/node.key
ssh $node_ssh_address sudo mv ./zrepl-config/ca.crt ./zrepl-config/node.crt ./zrepl-config/node.key /etc/zrepl/

```

After your node has required certificate files,
you need to copy config to node.
If you don't have config yet, skip to config generation and run these commands later:

```bash

node_config_path=$client_cert_path.yaml

nano $node_config_path

scp $node_config_path $node_ssh_address:./zrepl-config/zrepl.yml
ssh $node_ssh_address sudo mv ./zrepl-config/zrepl.yml /etc/zrepl/
ssh $node_ssh_address zrepl configcheck --config /etc/zrepl/zrepl.yml

# if configcheck is successful, restart the service
ssh $node_ssh_address sudo systemctl restart zrepl
ssh $node_ssh_address sudo systemctl status zrepl --no-pager

```

# Pull setup: source side

Add `global` and `jobs` objects:

```yaml
global:
  logging:
  # use syslog instead of stdout because it makes journald happy
  - type: syslog
    format: human
    level: warn
  monitoring:
  - type: prometheus
    listen: :9811
jobs:
```

- In `jobs`: Add a single snapshotting job
- - Replace `REPLACE_ME_SOURCE_DATASET` with your value(s)

```yaml
- name: automatic-snapshots
  type: snap
  filesystems:
    REPLACE_ME_SOURCE_DATASET: true
  # create snapshots with prefix `zrepl_` every 10 minutes
  snapshotting:
    # if you only want to transfer a backup, change type to manual
    type: periodic
    prefix: zrepl_
    interval: 10m
  pruning:
    keep:
    # delete all automatic snapshots older than 1 hour
    - type: grid
      grid: 1x1h(keep=all)
      regex: "^zrepl_.*"
    # keep all snapshots that don't have the `zrepl_` prefix
    - type: regex
      negate: true
      regex: "^zrepl_.*"
```

- In `jobs`: For each pull client add a separate source config:
- - Replace `REPLACE_ME_SOURCE_DATASET` with your value(s)
- - `<` at the end of dataset makes zrepl replicate dataset children, without it it will send only parent dataset
- - Don't forget to set a unique port for each source listener
- - Set `REPLACE_ME_CLIENT_CERT_NAME` to pull client name
- - Even though you can set several values in `client_cns`, zrepl does not support more than 1 client per source

To make sure that `client_cns` is correct, check the pull client certificate:

```bash
openssl x509 -in $client_cert_path.crt -noout -text | grep DNS:
```

```yaml
- name: source
  type: source
  filesystems:
    REPLACE_ME_SOURCE_DATASET<: true
  serve:
    type: tls
    listen: :8888
    ca:   /etc/zrepl/ca.crt
    cert: /etc/zrepl/node.crt
    key:  /etc/zrepl/node.key
    client_cns:
    - REPLACE_ME_CLIENT_CERT_NAME
  snapshotting:
    type: manual
```

# Pull setup: pull side

Add `global` and `jobs` objects:

```yaml
global:
  logging:
  # use syslog instead of stdout because it makes journald happy
  - type: syslog
    format: human
    level: warn
  monitoring:
  - type: prometheus
    listen: :9811
jobs:
```

Add basic pull job:

```yaml
- type: pull
  name: pull-from-source
  connect:
    type: tls
    address: REPLACE_ME_ADDRESS:REPLACE_ME_PORT
    ca:   /etc/zrepl/ca.crt
    cert: /etc/zrepl/node.crt
    key:  /etc/zrepl/node.key
    server_cn: REPLACE_ME
    dial_timeout: # optional, default 10s
  root_fs: REPLACE_ME
  # interval is low on purpose
  # after restart program waits the interval before attempting to do anything
  interval: 1m
  recv:
    placeholder:
      encryption: inherit
  conflict_resolution:
    initial_replication: all
```

`address` must be reachable, port must match `listen` port from source.

To make sure that `server_cn` is correct, check the pull client certificate:

```bash
openssl x509 -in $client_cert_path.crt -noout -text | grep DNS:
```

Set `root_fs` to dataset where you want your backups to be stored.

Set pruning. For example:

> fade-out scheme for snapshots starting with `zrepl_`
> - keep all created in the last hour
> - for snapshots older than 1h:
>   destroy snapshots such that we keep 6 each 1 hour apart
> - for snapshots older than 1h + 6h:
>   destroy snapshots such that we keep 14 each 1 day apart
> - for snapshots older than 1h + 6h + 14d:
>   destroy snapshots such that we keep 6 each 30 days apart
> - then destroy all snapshots older than 1h + 6h + 14d + 6x30d

```yaml
  pruning:
    keep_sender:
    # keep all non-zrepl snapshots
    # keep 3 zrepl snapshots
    - type: regex
      negate: true
      regex: "^zrepl_.*"
    - type: grid
      grid: 3x1h
      regex: "^zrepl_.*"
    keep_receiver:
    - type: grid
      grid: 1x1h(keep=all) | 6x1h | 14x1d | 6x30d
      regex: "^zrepl_.*"
    # keep all non-zrepl snapshots
    - type: regex
      negate: true
      regex: "^zrepl_.*"
```

Set replication settings:

```yaml
  replication:
    protection:
      # https://zrepl.github.io/configuration/replication.html
      # guarantee_resumability guarantee_incremental guarantee_nothing
      initial:     guarantee_resumability
      incremental: guarantee_resumability
```

# Many-to-many backup

Back up more than one filesystem:
Edit source config: `jobs.[name=source].filesystems.*`: set `true` for all required datasets.
Do not forget to also adjust snapshot configuration.

Pull data from several servers:
Edit pull config: add one more `type: pull` entry.

Back up different filesystems to different clients:
Edit source config: add one more `type: source` entry.

# Known errors

`error reading protocol banner length: EOF`:
most likely client name mismatch between server and client.
Check `client_cns`, `server_cn`, and CN/altName in certificate.

`error listing receiver filesystems`, `cannot determine whether root_fs exists`:
seems to have disappeared after system upgrade and reboot.
Not sure which action helped to solve the issue.

# Metrics

```bash

# check metrics manually
zrepl_host=nas-tulip.storage.lan
curl $zrepl_host:9811/metrics > ./zrepl-metrics.log

 cat << EOF > ./docs/backup/env/scrape-zrepl.yaml
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: external-zrepl
  namespace: prometheus
  labels:
    prometheus.io/instance: main
    instance.prometheus.io/main: enable
    instance.prometheus.io/prompp: enable
spec:
  scheme: HTTP
  staticConfigs:
  - labels:
      job: zrepl
      location: $cluster_name
    targets:
    - $zrepl_host:9811
  metricRelabelings:
  - targetLabel: instance # remove port from instance
    action: replace
    sourceLabels: [ instance ]
    regex: (.*):\d*
EOF

kl apply -f ./docs/backup/env/scrape-zrepl.yaml
kl apply -f ./docs/backup/alert.yaml

```

# Release all holds

```bash

parentDataset=petunia/restore
# if empty, will match all holds
holdPrefix=zrepl_last_received_
dryRun=true1

zfs list -H -t snapshot -r -o name $parentDataset |
while IFS=$'\t' read -r snapshot; do
  zfs holds -H "$snapshot" |
  while IFS=$'\t' read -r _ holdTag _; do
    if [[ ! "$holdTag" == "${holdPrefix}"* ]]; then
      continue;
    fi
    echo "zfs release '$holdTag' '$snapshot'"
    if [[ "$dryRun" == true ]]; then
      continue;
    fi
    sudo zfs release "$holdTag" "$snapshot"
  done
done

```

# Delete snapshots

```bash

parentDataset=petunia/restore
# if empty, will match all holds
snapshotPrefix=zrepl_
dryRun=true1

zfs list -H -t snapshot -r -o name $parentDataset |
while IFS=$'\t' read -r snapshot; do
  if [[ ! "$snapshot" == *"@${snapshotPrefix}"* ]]; then
    continue;
  fi
  echo "zfs destroy '$snapshot'"
  if [[ "$dryRun" == true ]]; then
    continue;
  fi
  sudo zfs destroy "$snapshot"
done

```
