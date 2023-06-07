
```yaml
      securityContext:
        runAsUser: 1000
        runAsGroup: 65534
        fsGroup: 65534
        fsGroupChangePolicy: OnRootMismatch
```

```yaml
  initContainers:
  - name: volume-mount-hack
    image: busybox
    command: ["sh", "-c", "chown -R 999:999 /data/demo"]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
```
