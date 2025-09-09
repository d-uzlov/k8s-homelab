
# install via script

```bash

curl https://get.docker.com | bash

# enable using docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# check that everything is working
docker run --rm hello-world

# reclaim space used by docker
# it's safe to run, only unused data will be deleted
docker system prune -a

```

# config

References:
- https://docs.docker.com/engine/daemon/
- https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file

```bash

mkdir -p ./docs/docker/env/
touch ./docs/docker/env/daemon.json

dockerd --validate --config-file ./docs/docker/env/daemon.json

```

Edit `daemon.json` manually.

I would recommend to at least use journald for logs:

```json
{
  "log-driver": "journald"
}
```

Note that you will need to manually delete and recreate all containers after you change `log-driver` option.

# install via ansible

```bash

ansible-galaxy role install geerlingguy.docker
ansible-galaxy collection install community.docker

ansible-inventory --graph docker

ansible-playbook ./docs/docker/playbook.yaml

```
