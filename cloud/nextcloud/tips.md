
# Rescan files after manual changes in filesystem

```bash
# for all users
kl -n nextcloud exec deployments/nextcloud -it -- php occ files:scan --all
# for a single user
kl -n nextcloud exec deployments/nextcloud -it -- php occ files:scan -- $userid
```

Sometimes you can still see files even without rescan.
But in my experience you can get permission issues: you can read these files but not modify them.
Running rescan seems to fix it.

# Brute-force protection FAQ

Nextcloud will temporarily lock you out of web UI if you fail several login attempts.

You can reset this:

```bash

# this is used to contain useful settings in older versions of nextcloud :-(
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:list brute_force_protection

# show status for an ip
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ security:bruteforce:attempts $ip_address
# unblock an ip-address
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ security:bruteforce:reset $ip_address

# It doesn't seem like there is a proper way to list all throttled IPs

# list throttled ips via DB
# apparently, this can be empty because redis is used?
# kl -n nextcloud exec pods/postgres-0 -- psql --username=nextcloud nextcloud -c 'SELECT * from oc_bruteforce_attempts'
kl cnpg -n nextcloud psql nextcloud-cnpg -- app -c 'SELECT * from oc_bruteforce_attempts'

redis_password=$(kl -n nextcloud get secret -l nextcloud=passwords --template "{{ (index .items 0).data.redis_password}}" | base64 --decode)
kl -n nextcloud exec deployments/redis -- redis-cli -a "$redis_password" KEYS '*' | grep -i brute
# for example:
kl -n nextcloud exec deployments/redis -- redis-cli -a "$redis_password" GET '3a3b047e3d074beac4385ef47fea7764/OC\Security\Bruteforce\Backend\MemoryCacheBackend94ba2723aa73ca1d9bbca3638888eaccb289619a'
# example output: 1743818060#7068ec443266b79f3de8e414659b929459f478c9#991c211900f8f69c0ce0ebce6f5cdf43d85b71c0
# the format is unreadable :-(

# the only sane way to deal with this is to disable brute force protection altogether :-(
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:system:set auth.bruteforce.protection.enabled --value false --type bool
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:system:set auth.bruteforce.protection.enabled --value true --type bool
# alternatively, you can whitelist 0.0.0.0/0 in the web UI
# Administration -> Security -> Add a new whitelist

# enable a disabled user
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ user:enable $username

```

References:
- https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#security

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
# you can place an additional file into the include directory
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
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ list
# show current config for all apps
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:list > config-list.json
# show current config for onlyoffice
kl -n nextcloud exec deployments/nextcloud -c nextcloud -- php occ config:list onlyoffice
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
