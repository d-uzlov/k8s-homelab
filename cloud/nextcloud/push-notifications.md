
# Push notifications

Nextcloud has push notifications system but it requires additional configuration to work.

Note that push server must be in the `trusted_proxies` CIDR.

References:
- https://github.com/nextcloud/notify_push

```bash
# ingress with wildcard certificate
kl label ns --overwrite nextcloud copy-wild-cert=main
kl apply -k ./cloud/nextcloud/notifications/ingress-wildcard/
kl -n nextcloud get ingress

kl apply -k ./cloud/nextcloud/notifications/httproute-public/
kl -n nextcloud get httproute

nextcloud_push_domain=$(kl -n nextcloud get ingress push-notifications -o go-template "{{ (index .spec.rules 0).host}}")
nextcloud_push_domain=$(kl -n nextcloud get httproute nextcloud-push-public -o go-template --template "{{ (index .spec.hostnames 0)}}")

 kl -n nextcloud exec deployments/nextcloud -c nextcloud -i -- bash - << EOF
set -eu
php occ app:enable notify_push
php occ app:update notify_push
php occ config:app:set notify_push base_endpoint --value "https://$nextcloud_push_domain"
EOF

kl apply -k ./cloud/nextcloud/notifications/
kl -n nextcloud get pod -o wide

```

# Cleanup

```bash
kl delete -k ./cloud/nextcloud/notifications/
kl delete -k ./cloud/nextcloud/notifications/httproute-public/
```

# Test

You can run test commands to trigger push notifications manually:

```bash
# self-test
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notify_push:self-test
# show number of connections and messages
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notify_push:metrics
# send a test notifications to user with id "admin"
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notification:test-push admin
# when using oidc provider, user id is uuid@provider.domain
# to test push notification, use only the uuid
# uuid can be found in personal settings -> sharing, or at nextcloud.example.com/settings/user/sharing
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ notification:test-push 99b556c5-2ae5-4bb9-a445-24b5346855ab
```

**Note**: Mobile app should register itself when connecting to server.
If you sign out and login again then it seems like it doesn't.
This can be fixed by clearing mobile app data.
