
# Changing PHP settings

```bash
# check out php config dir
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- bash -c 'echo $PHP_INI_DIR'
# or ask php to print its config 
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php -i

# the app is running through php-fpm, so maybe its configs will be more relevant to you
# print current config
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php-fpm -tt 2>&1
# find the config directory
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- cat /usr/local/etc/php-fpm.conf | grep include=
# by default php-fpm configs are located here:
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- ls /usr/local/etc/php-fpm.d/ -la
# you can place an addition file in the include directory
# after you do, you can check that the value you are interested in has really changed
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php-fpm -tt 2>&1 | grep pm
```

# Adjust chunk size on Nextcloud side

For upload performance improvements in environments with high upload bandwidth, the server’s upload chunk size may be adjusted:

Nextcloud uploads data in chunks.
If the chuck is too large, you can loose more progress when the connection breaks.
If the chunk is too small, chunk overhead will slow down uploads.

The default chunk size is 10485760 (10 MiB).
You can set a custom value, or set `0` to disable chunks
(all files will be uploaded in a single chunk).

```bash
# this command resets chunk size to default value
# change --value if you want to adjust it
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:app:set files max_chunk_size --value 10485760
```

By default ingress in this deployment uses `proxy-body-size: 15m`.
You need to update this value if you want to use chunks larger than 15 MB.

# Nat loopback speed considerations

NAT loopback speed may be less than native network speed.
In fact, it can be less than NAT port-forwarding speed.

For example:

- Direct connection: up 40 MB/s, down 65 MB/s
- NAT loopback: up 15 MB/s, down 20 MB/s

# Temp file location

You can change temp directory location.
Temp directory is used for storing chunks during uploading,
as well as for downloading Nextcloud addons.

References:
- https://docs.nextcloud.com/server/16/admin_manual/configuration_server/config_sample_php_parameters.html#all-other-configuration-options
- - `'tempdirectory' => '/tmp/nextcloudtemp',`
- - Override where Nextcloud stores temporary files.
Useful in situations where the system temporary directory
is on a limited space ram disk or is otherwise restricted,
or if external storages which do not support streaming are in use.
- - The Web server user must have write access to this directory.

# List available `occ` commands

```bash
# list all commands
php /var/www/html/occ list
# show current config for all apps
kl -n nextcloud exec deployments/nextcloud -it -- php /var/www/html/occ config:list > config-list.json
# show current config for onlyoffice
kl -n nextcloud exec deployments/nextcloud -it -- php /var/www/html/occ config:list onlyoffice
```

# TODO

https://github.com/nextcloud/all-in-one/blob/ee06a04f5191628691c843af667143aa1a163256/Containers/nextcloud/entrypoint.sh

Full text search

Test S3 speed?

Check out Memories app:
https://github.com/pulsejet/memories/
https://www.reddit.com/r/NextCloud/comments/z246f7/memories_google_photos_alternative_for_nextcloud/

Imaginary for preview generation:
https://github.com/nextcloud/previewgenerator
https://docs.nextcloud.com/server/24/admin_manual/installation/server_tuning.html#previews
https://github.com/nextcloud/all-in-one/blob/ee06a04f5191628691c843af667143aa1a163256/Containers/nextcloud/entrypoint.sh#L255

Use proper app checks instead of just checking that app folder exists.

Use NFS for the main app dir?
https://www.google.com/search?q=php+nfs+slow&ei=NF26WLb0HJCIyAW43YzQAg&gws_rd=cr&fg=1&hl=en
