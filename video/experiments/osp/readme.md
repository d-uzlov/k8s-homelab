
# Open Streaming Platform

References:
- https://gitlab.com/osp-group/flask-nginx-rtmp-manager
- https://open-streaming-platform.readthedocs.io/en/latest/install/install.html

This shit doesn't have any useful documentation, starts up for ~5 minutes, and then doesn't work.

It also doesn't have any useful logs. For fuck's sake, `ospworker5000 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)`, and nothing else.

There is next to zero support for containers. Fucking supervisord in a container.

It also expects to be the only thing running in the server. If you are running behind a reverse proxy — too bad.
You better set it up so that it doesn't do anything and just passes all the traffic to the apps, or else nothing will work.

It also wants to get you banned at LetsEncrypt.

# Deploy

```bash
kl create ns osp

# create loadbalancer service
kl apply -k ./video/ome/loadbalancer/
# get assigned IP to set up DNS or NAT port-forwarding
kl -n ome get svc

# setup wildcard ingress
kl label ns --overwrite osp copy-wild-cert=main
kl apply -k ./video/osp/ingress-core-wildcard/
kl apply -k ./video/osp/ingress-ejabberd-wildcard/
kl -n osp get ingress

kl apply -k ./video/osp/pvc/
kl -n osp get pvc

kl apply -k ./video/osp/
kl -n osp get pod -o wide
```

# Cleanup

```bash
kl delete -k ./video/osp/
kl delete -k ./video/osp/pvc/
kl delete ns osp
```

# Notes

- ejabberd is mandatory, osp will not work without it
- ejabberd tries to register its domain names on letsencrypt production server
- first username must be admin, or else you won't be able to log in
