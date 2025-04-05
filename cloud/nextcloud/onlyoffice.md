
# Onlyoffice integration

Nextcloud has integration with Onlyoffice app.
You need to deploy [onlyoffice](../onlyoffice/readme.md)
and configure connection settings to use it.

OnlyOffice app installation can take a long time
both for downloading the app and for running the cron job.

```bash

onlyoffice_jwt_secret=$(kl -n onlyoffice get secret onlyoffice-api --template {{.data.jwt_secret}} | base64 --decode)
# onlyoffice_public_domain=$(kl -n onlyoffice get ingress onlyoffice -o go-template "{{ (index .spec.rules 0).host}}")
onlyoffice_public_domain=$(kl -n onlyoffice get httproute onlyoffice-public -o go-template --template "{{ (index .spec.hostnames 0)}}")

 kl -n nextcloud exec deployments/nextcloud -c nextcloud -i -- bash - << EOF
set -eu
php occ app:enable onlyoffice
# onlyoffice is a better pdf viewer, but the default one will not let you use it
php occ app:disable files_pdfviewer
php occ config:app:set onlyoffice customizationFeedback --value false
php occ config:system:set onlyoffice StorageUrl --value "http://frontend.nextcloud.svc/"
php occ config:system:set onlyoffice jwt_header --value AuthorizationJwt
php occ config:system:set onlyoffice jwt_secret --value "${onlyoffice_jwt_secret}"
php occ config:system:set onlyoffice DocumentServerInternalUrl --value "http://onlyoffice.onlyoffice.svc/"
php occ config:system:set onlyoffice DocumentServerUrl --value "https://${onlyoffice_public_domain}/"
php -f /var/www/html/cron.php
EOF

```
