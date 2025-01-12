
# OIDC login

References:
- https://docs.goauthentik.io/integrations/services/nextcloud/
- [OpenID Connect user backend](https://github.com/nextcloud/user_oidc)
- - **Note**: `OpenID Connect Login` is a different plugin with a very different config.

# Authentik

- Create `nextcloud` app and `nextcloud` OAuth provider
- `Admin Interface -> Customization -> Property mappings -> Create`
- Set name to `Nextcloud Profile`
- Set scope name to `nextcloud-profile`
- Fill in `Description`, it will be shown in the login consent screen
- Set expression:

```python
# Extract all groups the user is a member of
authGroups = [group.name for group in user.ak_groups.all()]
groups = []

if 'nextcloud-admin' in authGroups:
  groups.append("admin")

return {
  "name": request.user.name,
  "nc-groups": groups,
  # To set a quota set the "nextcloud_quota" property in the user's attributes
  "quota": user.group_attributes().get("nextcloud_quota", "10 GB"),
  # To connect an already existing user, set the "nextcloud_user_id" property in the
  # user's attributes to the username of the corresponding user on Nextcloud.
  "user_id": user.attributes.get("nextcloud_user_id", str(user.uuid)),
}
```

- `Admin Interface -> Applications -> Providers -> nextcloud -> Edit -> Advanced protocol settings -> Scopes`: add `Nextcloud Profile` into `Selected Scopes`

- For each required user set quota: `Admin Interface -> Directory -> Users -> username -> Edit -> Attributes`: set `nextcloud_quota: 100 GB`

# Nextcloud setup

```bash

kl -n nextcloud exec deployments/nextcloud -- php occ app:enable user_oidc
```

Set up OIDC: `Administration settings -> OpenID Connect -> Registered Providers -> +`

- Set `identifier` to a readable string, this will be shown in the login screen.
- `identifier` can't be changed after initial creation
- Fill in `Client ID` and `Client secret` from authentik provider page
- Set `Discovery endpoint` to `OpenID Configuration URL` value from authentik provider page
- Set scope to `email profile nextcloud-profile`
- Set `Groups mapping` to `nc-groups`
- ! Disable `Use unique user id`
- ! Disable `Use provider identifier as prefix for ids`
- Enable `Use group provisioning`

# Tips for oidc maintenance

```bash
# check list of existing groups and their users
# format is:
# - group-id
#   - user-name
kl -n nextcloud exec deployments/nextcloud -- php occ group:list

# disable native login, all users will be redirected to authentik
kl -n nextcloud exec deployments/nextcloud -- php occ config:app:set --value=0 user_oidc allow_multiple_user_backends
# allow users to use native login
kl -n nextcloud exec deployments/nextcloud -- php occ config:app:set --value=1 user_oidc allow_multiple_user_backends
# alternatively, use `direct=1` to bypass this setting
# https://nextcloud.example.com/login?direct=1
```
