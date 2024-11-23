
# DuckDNS

Link: https://www.duckdns.org/

- [+] 5 free subdomains
- [?] 1 available parent domain: `duckdns.org`
- [+] Automatic wildcard record: `*.example.duckdns.org`
- [+] DNS01 Letsencrypt challenge is possible
- - Including cert-manager integration
- [+] `duckdns.org` is a public domain suffix in 2024: https://github.com/publicsuffix/list/blob/f781a9a41c45c1438be97543c8e2d31530ad3429/public_suffix_list.dat#L12684
- [-] No custom entries: only main and wildcard are available
- [-] Often down, or just very slow

# yDNS

Link: https://ydns.io/

- [+] Unlimited subdomains
- - Limited by "fair use"
- [?] 1 available parent domain: `ydns.eu`
- [-] No custom entries
- [-] Doesn't even set wildcard entry
- [-] DNS01 is not available
- [-] Seems abandoned: the official GitHub repo is cleared
- [-] `ydns.eu` is NOT a public domain suffix in 2024

# ipv64

Link: https://ipv64.net/dyndns

- [+] 3 free subdomains
- [+] Has lots of parent domains to choose from
- [+] Allows custom entries
- [+] DNS01 is available (theoretically)
- - Via TXT edits
- - Via CNAME
- [-] None of the domains are public domain suffixes in 2024
- - PR for this was rejected due to issues with the domain info: https://github.com/publicsuffix/list/pull/1687

# ClouDNS

Link: https://www.cloudns.net/

- [?] 1 free subdomain
- [?] Several parent domains available
- [+] Allows any custom entries
- [+] All parent domains are public domain suffixes in 2024: https://github.com/publicsuffix/list/blob/f781a9a41c45c1438be97543c8e2d31530ad3429/public_suffix_list.dat#L12453-L12472
- [-] You are limited by 50 records in total, including any A, NS, CNAME, etc.

# deSEC

Link: https://desec.io/

- [-] Registrations are closed

# FreeDNS

Link: https://freedns.afraid.org/

- [-] Deletes inactive users
- - Inactivity period is unknown
- - 1 month?
- - - https://www.reddit.com/r/OPNsenseFirewall/comments/15o7giv/comment/jvq000u/
- - > Periodically I forget to update my account by logging in.
    > I get frozen for a while until I log in and update.
- - - https://www.reddit.com/r/homelab/comments/v3hi8b/comment/iazrinc/
- - My personal account got deleted a few years ago, just because I didn't log in for a while
- [-] Apparently it's easy to get banned
- - https://www.reddit.com/r/homelab/comments/v3hi8b/anyone_ever_get_banned_from_freednsafraidorg/
- - https://www.reddit.com/r/webhosting/comments/1aoooh4/comment/kxa8sn9/
- - https://www.reddit.com/r/TOR/comments/uezlh3/psa_freednsafraidorg_banning_users_logging_in/

# no-ip

Link: https://www.noip.com/

- [-] `Confirm Hostname Every 30 Days via link in email` in the free tier
- [+] Reddit is happy with the reliability

# Dynu

Link: https://www.dynu.com/

- [+] All provided domains are public suffixes in 2024: https://github.com/publicsuffix/list/blob/b00d15ea62059a24d57cac96740c98dcb80b6edc/public_suffix_list.dat#L12968-L12985
- [+] 4 free 3rd level domains
- [+] Wildcard records
- [+] No auto deletion
- [+] Custom DNS records: A, AAAA, CNAME, PTR (?), MX, SRV
- [-] TXT records are not available in the free tier, except ACME validation
- [-] NS records are not available

# Free my ip

Link: https://freemyip.com/

- [+] Apparently you can create domains without registration?
- [+] `freemyip.com` is a public domain suffix in 2024: https://github.com/publicsuffix/list/blob/f781a9a41c45c1438be97543c8e2d31530ad3429/public_suffix_list.dat#L13389C1-L13389C13
- [-] Subdomains are deleted after a year of inactivity
- [+] Fetching the update URL counts as activity, resetting subdomain death timeout
- [+] Automatic wildcard record: `*.example.freemyip.com`
- [+] DNS01 is available (theoretically)
- - Via TXT edits only
- [-] No custom entries: only main and wildcard are available

# eu.org

Link: https://nic.eu.org/

- [-] Effectively, registration is broken
- - Domains are approved manually by a single person,
approvals were always long, but at the moment of writing this
that person seems to have stopped responding for several months
- - Seems to be non-operational since around mid-2023
- - https://www.reddit.com/r/selfhosted/comments/1av6awf/euorg_validation_speed/
- [+] Seems to be a proper 3rd level domain which can be delegated

# myaddr

Link: https://myaddr.tools/

- [-] `myaddr.*` is NOT a public domain suffix in 2024
- [+] Unlimited registrations
- [+] Wildcard record
- [+] DNS01 is available

# DynV6

Link: https://dynv6.com/

- [-] Seems dead
