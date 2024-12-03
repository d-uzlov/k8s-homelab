
# PHP FPM liveness check

This image is used for liveness check of nextcloud main container.

References:
- https://github.com/renatomefi/php-fpm-healthcheck

# Build

You can rebuild the image. Don't forget to set a valid user name.

```bash
username=something
docker build ./cloud/nextcloud/nc-liveness-check/ -t "$username"/k8s-snippets:fpm-healthcheck-3.18.3
docker push "$username"/k8s-snippets:fpm-healthcheck-3.18.3
```
