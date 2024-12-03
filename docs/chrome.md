
# Reset DNS cache in Google Chrome

1. Open chrome DNS page:
    `chrome://net-internals/#dns`
2. Press "Clear host cache".
3. Then close and re-launch chrome.

# Disable HSTS in chrome

Type `thisisunsafe` when the "Certificate error" page is open.

Beware that this completely disables checks for the whole domain.

Alternatively, delete site from HSTS list in [Chrome settings](chrome://net-internals/#hsts).

Note that this won't work if the site is in the preloaded HSTS list.
