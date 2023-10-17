
# Compatibility

Apparently, v3.xx is supposed to support k8s v1.xx.
So, v3.26 only supports k8s v1.26, and is not guaranteed to work on k8s v1.27 or v1.28.

# Versions

- v1.25.0 and v1.25.1 are known to work fine.
- v1.26.0: For some reason cascaded resource deletion doesn't work
- v1.26.1 seems to work fine, but it doesn't support eBPF in Debian 12: https://github.com/projectcalico/calico/issues/8001
- v3.26.3 breaks pod connectivity. Roughly 1/4th of ingress requests either hang for 5 seconds or simply never finish
- - Deploy `./test/ingress` and run this: `while true; do time curl https://echo-wildcard.meoe.duckdns.org; sleep 0.1; done`
- - With the same ingress test: direct access via load balancer service work without issues
- - Tested both with and without eBPF
- - Note: I don't remember if `externalTrafficPolicy` affects this

# v3.26.0 test

```bash
kl create ns echo
kl apply -k ./test/echo/ && sleep 5 && kl -n echo get pod && kl delete -k ./test/echo/ && sleep 1 && kl -n echo get all
```

Good output example:
```bash
NAME                             READY   STATUS        RESTARTS   AGE
pod/echoserver-96ffcc7c8-7k4xn   1/1     Terminating   0          8s
```

Bad output example:
```bash
NAME                             READY   STATUS        RESTARTS   AGE
pod/echoserver-96ffcc7c8-7k4xn   1/1     Running   0          8s

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/echoserver-96ffcc7c8   1         1         1       8s
```
