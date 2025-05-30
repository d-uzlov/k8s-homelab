
# Convenient setup

Make sure to adjust configs using instructions
from [bash-setup](./bash-setup.md).

You can quickly run all commands from there
if you have it in your local filesystem:

```bash
# apply everything to current user
sed -n '/```bash/,/```/{//!p;}' ./docs/bash-setup.md | bash
# apply everything to root user
sed -n '/```bash/,/```/{//!p;}' ./docs/bash-setup.md | sudo bash
# you can configure remote system via ssh
sed -n '/```bash/,/```/{//!p;}' ./docs/bash-setup.md | ssh $remote_hostname
sed -n '/```bash/,/```/{//!p;}' ./docs/bash-setup.md | ssh $remote_hostname sudo bash

# save script to run it somewhere else
sed -n '/```bash/,/```/{//!p;}' ./docs/bash-setup.md > ./init-user.sh
# run script from the web
curl https://raw.githubusercontent.com/d-uzlov/k8s-homelab/refs/heads/master/docs/bash-setup.md | sed -n '/```bash/,/```/{//!p;}' | bash

```

# Settings for new users

When creating a new user, contents of `/etc/skel/` directory are copied into the user home folder.
You can adjust `.bashrc` and other files in that directory to change the default settings.

# Docker completion

```bash
sudo curl https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh
```

# kind completion

```bash
source <(kind completion bash)
```

# Print CPU temperature

```bash
# without external tools
# shows only some temps
paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/'

sudo apt-get install -y lm-sensors
sensors
```

# Stress test

References:
- https://github.com/ColinIanKing/stress-ng
- https://github.com/ColinIanKing/stress-ng?tab=readme-ov-file#examples
- https://github.com/amanusk/s-tui
- https://github.com/amanusk/s-tui?tab=readme-ov-file#simple-installation

```bash
stress --cpu 4 --vm 2 --timeout 10s
# s-tui can run `stress`
s-tui

sudo add-apt-repository ppa:colin-king/stress-ng
sudo apt update
sudo apt install stress-ng
stress-ng --cpu 4 --vm 2 --fork 1 --timeout 10s --metrics
```

# Convert CRLF line endings into linux format

```bash
sudo apt install dos2unix
git ls-files -z | xargs -0 dos2unix
```
