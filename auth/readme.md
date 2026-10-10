
# Comparison table from reddit

References:
- https://www.reddit.com/r/homelab/comments/1fm01bj/the_impossible_quest_to_single_signon/

| Area                   | Authelia | Authentik  | Casdoor  | Kanidm  | Keycloak  | Zitadel    |
| ---------------------- | -------- | ---------- | -------- | ------- | --------- | ---------- |
| Resource Usage         | ✅ 27MB | ❌ 900MB   | ✅ 32MB | ✅ 17MB | ❌ 760MB | 🟠 124MB   |
| LDAP / AD              | ✅      | ✅         | ✅      | 🟠 1    | ✅       | 🟠 2       |
| Design                 | ✅      | ❌         | ✅      | ✅      | ✅       | ✅         |
| Passkey / Webauthn     | ✅      | ✅         | ✅      | ✅      | 🟠 3     | 🟠 2       |
| AD Groups              | ✅      | ✅         | ✅ 9    | ❌      | ✅ 4     | ✅         |
| RFC8628 (Device Grant) | 🟠      | ✅         | ✅      | ❌      | ✅       | ✅         |
| High availability      | 🟠6     | ✅Postgres | ✅ 10   | 🟠7     | ?         | ✅Postgres |
| Custom claims          | ?       | ✅         | ✅ 8    | ?        | ?         | ❌        |

1. LDAP server has to support Ldap Sync, and in any case the password from the directory won't be used.
2. Passkey currently cannot be used with external identity providers like Active Directory
3. You can implement Passkey in the authentication flow,
  but you can't implement a logic that would let the user login 
  with password if no passkey has been defined yet.
  It's Passkey only, or password only, or both, but not password IF no-passkey-defined
4. Authentication based on Client can be done with a third party provider
6. Authelia is stateless. I uses postgres for metadata. But you also need LDAP backend with HA support,
  and it doesn't seem like there there are many available. KaniDM can be used with replication setup, but it has its own issues.
7. KaniDM does't have a cluster mode. It does have replication with eventual consistency.
8. Requested in https://github.com/casdoor/casdoor/issues/3617, now available as Token attributes with the `JWT-Custom` token format:
  https://casdoor.ai/docs/application/terminology#token-attributes
9. With "Enable groups" in the LDAP settings, LDAP sync imports groups and OUs as Casdoor groups and assigns users by `memberOf`:
  https://casdoor.ai/docs/ldap/config
10. Stateless when sessions are stored in Redis (`redisEndpoint`), so several replicas can run against a shared database (MySQL or Postgres).
  The Helm chart has `replicaCount` and autoscaling: https://casdoor.ai/docs/basic/try-with-helm
  Scheduled jobs such as LDAP auto-sync run on every replica, there is no leader election.

Additional notes:
- Casdoor has very bad support on its github
- KaniDM: request for Device Grant: https://github.com/kanidm/kanidm/issues/1523
- - Apparently, it has low priority for them
- KaniDM: does not support plain HTTP between ingress and server
- Authentik: request for QR code auth: https://github.com/goauthentik/authentik/issues/9883
- - No attention from developers
- Authelia: Device Grant was added in Beta-7: https://www.authelia.com/roadmap/active/openid-connect-1.0-provider/#beta-7
- - I can't find any info on how to use it in the docs

# Comparison from lastlogin-net/obligator

References:
- https://github.com/lastlogin-net/obligator/blob/main/README.md#comparison-is-the-thief-of-joy

|                             | obligator | Portier   | Rauthy | Authelia    | Authentik | KeyCloak   | Vouch     | oauth2-proxy | Dex       | Ory Stack    | Zitadel  | Casdoor    | Kanidm    |
| --------------------------- | --------- | --------- | ------ | ----------- | --------- | ---------- | --------- | ------------ | --------- | ------------ | -------- | ---------- | --------- |
| Simple                      | ✅        | ✅       | ✅       | ✅       | ❌        | ❌        | ❓        | ❓           | ❓         | ❌          | ❌       | ❓         | ❓        |
| Anonymous auth              | ✅        | ✅       | ✅       | ❌       | ❌        | ❌        | ❌       | ❌          | ❌         | ❌          | ❌       | ❌        | ❌        |
| Multi-domain auth           | ❌        | ❓        | ❓        | ❌       | ❌       | ❌         | ❌       | ❌          | ❓         | ❌          | ❓        | ❓         | ❌        |
| Passwordless email login    | ✅        | ✅       | ❌       | ❌       | ❌        | ❌        | ❌       | ❌          | ❌         | ✅          | ❌       | ❓         | ❌        |
| HTTP API                    | ✅        | ❓        | ✅       | ❌       | ✅        | ✅        | ❌       | ❌          | ✅         | ✅         | ✅        | ❓         | ✅        |
| Forward auth                | ✅        | ❓        | ✅       | ✅       | ✅        | ✅        | ✅       | ✅          | ❓         | ✅          | ❓         | ❓        | ❌        |
| Trusted header auth         | ❌        | ❓        | ✅       | ✅       | ✅        | ❌        | ❌       | ❌          | ❓         | ✅          | ❓         | ❓        | ✅        |
| Upstream OIDC/OAuth2        | ✅        | ❌       | ✅       | ❌       | ✅        | ✅        | ✅       | ✅          | ✅        | ✅           | ✅       | ❓         | ❌        |
| SAML                        | ❌        | ❌       | ❓        | ❌       | ✅        | ✅        | ❌       | ❌          | ✅        | Needs coding | ✅        | ❓         | ❌        |
| LDAP                        | ❌        | ❌       | ❓        | ✅       | ✅        | ✅        | ❌       | ❌          | ✅        | Needs coding | ✅        | ❓         | ✅        |
| MFA                         | ❌        | ❓        | ✅       | ✅       | ✅        | ✅        | ❌       | ❌          | ❓         | ✅          | ✅        | ❓         | ✅        |
| Standalone reverse proxy    | ❌        | ❌       | ❓        | ❌       | ✅        | ✅        | ❌       | ✅          | ❌        | ✅          | ❓         | ❓         | ❌        |
| Admin GUI                   | ❌        | ❌       | ✅       | ✅       | ✅        | ✅        | ❌       | ❌          | ❓         | ✅          | ✅        | ❓         | ❌        |
| Dynamic client registration | ✅        | ❌       | ✅       | ❌       | ❌        | ❓         | ❌       | ❌          | ❌        | ✅          | ❌        | ❓         | ❌        |
| Passkey support             | ❌        | ❓        | ✅       | ❓        | ❓         | ❓        | ❓        | ❓           | ❓         | ❓           | ❓        | ❓         | ✅        |
| Vanity                      | 772 stars | 571 stars | 528 stars | 23k stars | 16k stars | 26k stars | 3k stars | 11k stars    | 9.8k stars | 16k stars    | 10k stars | 11k stars | 3.3k stars |
| Language                    | Go        | Rust      | Rust      | Go        | Python    | Java      | Go       | Go           | Go         | Go           | Go        | Go        | Rust       |
| Dependencies                | 5         | 21        | 73        | 49        | 54        | ❓        | 16       | 36           | 36         | 58           | 81        | 68        | 116        |
| Lines of code               | ~5600     | ~9500     | ~59000    | ~148000   | ~247000   | ~869000   | ~5500    | ~54000       | ~63500     | ~330000      | ~603000   | ~113000   | ~239000    |

# Comparison from github/bmaupin gist

References:
- https://gist.github.com/bmaupin/6878fae9abcb63ef43f8ac9b9de8fafd

|                     | Keycloak    | WSO2         | Gluu          | CAS         | OpenAM    | Shibboleth IdP | ZITADEL     | Authentik | Authelia | lemonldap-ng       | logto   |
| --------            | --------    | --------     | --------      | --------    | --------  |--------------- | --------    | --------- | -------- | ------------       | ------  |
| OpenID              | yes         | yes          | yes           | yes         | yes       | yes            | yes         | yes       | yes      | yes                | yes     |
| MFA                 | yes         | yes          | yes           | yes         | yes       | yes            | yes         | yes       | yes      | yes                | yes     |
| Admin UI            | yes         | yes          | yes           | yes         | yes       | no             | yes         | Yes       |          | yes                | yes     |
| OpenJDK             | yes         | yes          | partial       | yes         | yes       | partial        |             |           |          |                    |         |
| Identity brokering  | yes         | yes          | yes           |             |           |                | yes         |           |          | yes                | yes     |
| Middleware          | Quarkus     | WSO2 Carbon? | Jetty, Apache | Java        | Java      | Jetty, Tomcat  | CockroachDB |           |          | Apache, Nginx, PHP | Express |
| Open source         | yes         | nominally    | yes           | yes         | yes       | yes            | yes         | yes       | yes      | yes                | yes     |
| Commercial support  | yes         | yes          | yes           | third-party | yes       | third-party    | yes         | yes       |          | yes                | yes     |
| Federation metadata | no          | yes          |               |             |           | yes            | no          |           |          | yes                | yes     |
| Metadata from URL   | import only | yes          |               |             |           | yes            | yes         |           |          | yes                | yes     |
| Configuration       | easy        |              | difficult     |             | difficult | easy/medium    |             |           |          | easy/medium        | easy    | 
