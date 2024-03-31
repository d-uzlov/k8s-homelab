
# Graceful node shutdown

According to documentation it should be as easy as enabling `shutdownGracePeriod` and `shutdownGracePeriodCriticalPods` in config:
https://kubernetes.io/docs/concepts/architecture/nodes/#graceful-node-shutdown

It isn't.

Official documentation doesn't say it explicitly,
but it vaguely implies that you at least need to use `systemd` to run services.

There are several unintuitive issues that can prevent graceful shutdown:

**1. Kubelet may silently fail to register shutdown delay hook**

First, check the list of `systemd` hooks to see if kubelet at least registered itself for graceful shutdown.

```bash
cat /etc/systemd/logind.conf.d/99-kubelet.conf
# file should contain something like this: InhibitDelayMaxSec=30

systemd-inhibit --list
# output should contain something like this:
# kubelet      0   root 1079   kubelet      shutdown Kubelet needs time to handle node shutdown delay
```

If `systemd-inhibit` output does not contain the kubelet entry, it's probably because someone overrides `InhibitDelayMaxSec`.

Any of the following configs can set the wrong limit:
- `/etc/systemd/logind.conf`
- `/etc/systemd/logind.conf.d/*.conf`
- `/run/systemd/logind.conf.d/*.conf`
- `/usr/lib/systemd/logind.conf.d/*.conf`

Grep `InhibitDelayMaxSec` in files in these directories.

In Ubuntu and Debian the limit is 30 seconds:
- `/usr/lib/systemd/logind.conf.d/unattended-upgrades-logind-maxdelay.conf`

Uninstall `unattended-upgrades` to fix it.

References:
- https://github.com/kubernetes/kubernetes/issues/107043

**2. You must use proper shutdown method**

`/usr/sbin/shutdown` and `/usr/sbin/reboot` are aliases to `/bin/systemctl`.

But `systemctl` does not respect `systemd` inhibitor locks when called as `shutdown` or `reboot`.

You must use `systemctl poweroff` or `systemctl reboot` respectively.

If you don't control how the node is shut down,
replace `/usr/sbin/shutdown` with the following script:
```bash
#!/bin/bash
exec systemctl poweroff
```

Alternatively, apparently scheduled shutdown also works:
```bash
shutdown -h +1
```

DBus shutdown is supposed to work fine but I don't have a way to test this.

Shutdown events from power button are supposed to work fine.
I don't have a physical machine to test it.

Shutting down a VM with `qemu-guest-agent` installed also seems to work fine.

References:
- https://github.com/kubernetes/website/pull/26963#issuecomment-794920869
- https://github.com/systemd/systemd/issues/949

**3. Systemd did not respect shutdown lock in older versions**

Apparently, you need version `248` or newer.
I didn't test to find out real minimum version.

Results in this documentations were obtained using version `249.11` in `Ubuntu 22.04.1`.

References:
- https://github.com/systemd/systemd/issues/949
- https://github.com/systemd/systemd/pull/18316
- https://github.com/systemd/systemd/pull/9356
- https://github.com/systemd/systemd/commit/8885fed4e3a52cf1bf105e42043203c485ed9d92

# Graceful node shutdown doesn't delete pods

References:
- https://github.com/kubernetes/kubernetes/pull/108941
- https://github.com/kubernetes/kubernetes/issues/113278
- https://github.com/kubernetes/kubernetes/issues/113278#issuecomment-1406294874
- https://stackoverflow.com/a/75761843
- https://stackoverflow.com/questions/40296056/kubernetes-delete-all-the-pods-from-the-node-before-reboot-or-shutdown-using-k
- https://kubernetes.io/docs/concepts/architecture/garbage-collection/
- https://longhorn.io/docs/archives/0.8.0/users-guide/node-failure/

# Non-graceful shutdown

Apparently, it's possible to force-remove node and all it's pods from the cluster.

https://kubernetes.io/blog/2022/05/20/kubernetes-1-24-non-graceful-node-shutdown-alpha/
