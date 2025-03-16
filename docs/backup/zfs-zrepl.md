
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

# Pull setup

We will set up source and pull configuration.
Push and target configuration is also available but is not discussed here.

First generate certificates for CA and all nodes:
- [x509 Certificates](../cert-x509.md)

```bash

# paths to certificates, without file extension
ca_cert_path=./docs/backup/env/b2788.meoe.cloudns.be-ca

source_cert_path=./docs/backup/env/b2788-ssd-nas.b2788.meoe.cloudns.be
source_cert_name=ssd-nas.b2788.meoe.cloudns.be
source_file_name=ssd-nas.storage.lan

source_dataset=nvme/test/data
source_port=8888
# pull job should be able to access this address
source_public_address=ssd-nas.storage.lan:$source_port

pull_cert_path=./docs/backup/env/b2788-hdd-tn.b2788.meoe.cloudns.be
pull_cert_name=hdd.tn.lan
pull_file_name=hdd.tn.lan

pull_dataset=main/backup
pull_cert_name=hdd.tn.lan

source_ssh=ssd-nas.storage.lan
pull_ssh=hdd.tn.lan

sed \
  -e "s~AUTOREPLACE_SOURCE_DATASET~$source_dataset~" \
  -e "s/AUTOREPLACE_CLIENT_CERT_NAME/$pull_cert_name/" \
  -e "s/AUTOREPLACE_LISTEN_PORT/$source_port/" \
  ./docs/backup/source-template.yaml \
  > ./docs/backup/env/$source_file_name-zrepl.yml

ssh $source_ssh rm -rf ./zrepl-config/
ssh $source_ssh mkdir -p ./zrepl-config/
scp $ca_cert_path.crt     $source_ssh:./zrepl-config/ca.crt
scp $source_cert_path.crt $source_ssh:./zrepl-config/node.crt
scp $source_cert_path.key $source_ssh:./zrepl-config/node.key
scp ./docs/backup/env/$source_file_name-zrepl.yml $source_ssh:./zrepl-config/zrepl.yml
# skip source commands below if you are running zrepl manually
ssh $source_ssh sudo mv ./zrepl-config/ca.crt ./zrepl-config/node.crt ./zrepl-config/node.key ./zrepl-config/zrepl.yml /etc/zrepl/
ssh $source_ssh zrepl configcheck --config /etc/zrepl/zrepl.yml
ssh $source_ssh sudo systemctl restart zrepl
ssh $source_ssh sudo systemctl status zrepl --no-pager

sed \
  -e "s/AUTOREPLACE_SOURCE_ADDRESS/$source_public_address/" \
  -e "s/AUTOREPLACE_SOURCE_CERT_NAME/$source_cert_name/" \
  -e "s~AUTOREPLACE_DATASET~$pull_dataset~" \
  ./docs/backup/pull-template.yaml \
  > ./docs/backup/env/$pull_file_name-zrepl.yml

ssh $pull_ssh rm -rf ./zrepl-config/
ssh $pull_ssh mkdir -p ./zrepl-config/
scp $ca_cert_path.crt   $pull_ssh:./zrepl-config/ca.crt
scp $pull_cert_path.crt $pull_ssh:./zrepl-config/node.crt
scp $pull_cert_path.key $pull_ssh:./zrepl-config/node.key
scp ./docs/backup/env/$pull_file_name-zrepl.yml $pull_ssh:./zrepl-config/zrepl.yml
# skip pull commands below if you are running zrepl manually
ssh $pull_ssh sudo mv ./zrepl-config/ca.crt ./zrepl-config/node.crt ./zrepl-config/node.key ./zrepl-config/zrepl.yml /etc/zrepl/
ssh $pull_ssh zrepl configcheck --config /etc/zrepl/zrepl.yml
ssh $pull_ssh sudo systemctl restart zrepl
ssh $pull_ssh sudo systemctl status zrepl --no-pager

```

# Many-to-many backup

Back up more than one filesystem:
Edit source config: `jobs.[name=source].filesystems.*`: set `true` for all required datasets.
Do not forget to also adjust snapshot configuration.

Pull data from several servers:
Edit pull config: add one more `type: pull` entry.

Back up different filesystems to different clients:
Edit source config: add one more `type: source` entry.

# Knows errors

`error reading protocol banner length: EOF`:
most likely client name mismatch between server and client.
Check `client_cns`, `server_cn`, and CN/altName in certificate.

`error listing receiver filesystems`, `cannot determine whether root_fs exists`:
seems to have disappeared after system upgrade and reboot.
Not sure which action helped to solve the issue.
