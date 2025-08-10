
# textfile exporters

References:
- https://github.com/prometheus-community/node-exporter-textfile-collector-scripts


# Install

```bash

sudo apt install -y moreutils
sudo apt install -y python3-apt python3-prometheus-client

wget -q https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/raw/refs/heads/master/apt_info.py

# test
chmod +x ./apt_info.py
./apt_info.py
sudo mv ./apt_info.py /opt/apt_info.py

# enable automatic apt-update once per day
# on proxmox you don't need this
echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/99_auto_apt_update.conf

 sudo tee /etc/systemd/system/node-textfile-apt_info.service << EOF
[Unit]
Description="apt_info from node-exporter-textfile-collector-scripts repo"

[Service]
ExecStartPre=mkdir -p /tmp/node-exporter-textfile/
ExecStart=bash -c "/opt/apt_info.py | sponge /tmp/node-exporter-textfile/apt.prom"
EOF

 sudo tee /etc/systemd/system/node-textfile-apt_info.timer << EOF
[Unit]
Description="Run node-textfile-apt_info.service every 10 minutes"

[Timer]
OnActiveSec=20sec
OnUnitActiveSec=10min
Unit=node-textfile-apt_info.service

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart node-textfile-apt_info.timer
sudo systemctl enable node-textfile-apt_info.timer
systemctl status --no-pager node-textfile-apt_info.timer
systemctl status --no-pager node-textfile-apt_info.service
journalctl -u node-textfile-apt_info

```
