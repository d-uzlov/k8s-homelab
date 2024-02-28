
# k8s_gateway

This deployment creates a local DNS server that resolves
ingress and load balancer addresses in LAN.
It can also resolve gateway addresses and virtual servers
but I don't use any in this repo.

You can use it to set up split horizon DNS.

It seems like by default k8s_gateway proposes you
to use it as a primary DNS server,
because it will forward unknown requests to node's `resolv.conf`.
Setup in this repo breaks this. You are supposed to use this deployment
only for relevant zones, but not as a primary DNS server in your system

Aside from ingress domains, this deployment is also configured
to resolve `<svc>.<namespace>.kubelb.lan` to addresses of load balancer services.

It will also technically answer to domains like `<svc>.<namespace>`.
This should not cause any issues if you don't use it as a primary DNS server
and only route requests to certain predetermined domains.

Alternatively, you can add annotations
`coredns.io/hostname` or `external-dns.alpha.kubernetes.io/hostname`
to your services to make them available as `<svc>.<namespace>.<annotation-value>`.

References:
- https://github.com/ori-edge/k8s_gateway

# Generate config

You only need to do this when updating the app.

```bash
helm repo add k8s_gateway https://ori-edge.github.io/k8s_gateway/
helm repo update k8s_gateway
helm search repo k8s_gateway/k8s-gateway --versions --devel | head
helm show values k8s_gateway/k8s-gateway > ./ingress/dns-k8s-gateway/default-values.yaml
```

```bash
helm template \
  exdns \
  k8s_gateway/k8s-gateway \
  --version 2.0.4 \
  --namespace exdns \
  --values ./ingress/dns-k8s-gateway/values.yaml \
  | sed -e '\|helm.sh/chart|d' -e '\|# Source:|d' -e '\|app.kubernetes.io/managed-by|d' -e '\|app.kubernetes.io/instance|d' -e '\|app.kubernetes.io/part-of|d' \
  > ./ingress/dns-k8s-gateway/exdns.gen.yaml
```

# Deploy

```bash
kl create ns exdns
kl label ns exdns pod-security.kubernetes.io/enforce=baseline
kl apply -k ./ingress/dns-k8s-gateway/
kl -n exdns get pod -o wide

# get load balancer external ip
kl -n exdns get svc exdns-k8s-gateway
```

# Cleanup

```bash
kl delete -k ./ingress/dns-k8s-gateway/
kl delete ns exdns
```

# DNS re-routing setup

I use OPNSense with Unbound DNS plugin.

There you can go to `Query Forwarding`
and add all the domains you are interested in to the list,
pointing to load balancer address of `exdns-k8s-gateway` service.

If you add `example.com` then all `*.example.com` requests
will be redirected to this deployment.

# Coredns setup for ingress loopback

When using LAN-local IPs in LAN DNS server there may be connectivity issues
when some workload inside the cluster tries to connect to exposed service.

For ingress you can fix it by editing coredns config

- Open the config: `kl -n kube-system edit cm coredns`
- Insert a line before line with `kubernetes` plugin:
- - `rewrite name regex (.+)\.example\.duckdns\.org nginx-controller.ingress-nginx.svc.cluster.local answer auto`
- - Replace `example\.duckdns\.org` with your domain
