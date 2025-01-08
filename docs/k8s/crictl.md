
# crictl setup

```bash
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock
```

This way you won't have to add `--runtime-endpoint unix:///run/containerd/containerd.sock` to each and every `crictl` command.

# Clear space on disk

```bash
# remove all currently unused images
sudo crictl rmi --prune
```

# crictl containers

```bash
# list running
sudo crictl ps
# list all
sudo crictl ps -a

container_id=aa84f2c75afac
sudo crictl logs $container_id

# list and remove stopped containers
sudo crictl ps -s exited |
    cut -f1 -d" " |
    xargs -L 1 -I {} -t sudo crictl rm {}
```

# crictl pods

```bash
# list pods
sudo crictl pods

# list and stop
sudo crictl pods |
    cut -f1 -d" " |
    xargs -L 1 -I {} -t sudo crictl stopp {}
# list and delete, requires pods to be stopped
sudo crictl pods |
    cut -f1 -d" " |
    xargs -L 1 -I {} -t sudo crictl rmp {}
```

# Other `crictl` commands

References:
- https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/
