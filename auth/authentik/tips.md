
# Authentik logout doesn't affect application cookies

References:
- https://github.com/goauthentik/authentik/issues/2023

# Set dark theme by default

> In admin panel, open the last settings of one of these items
> - Brand settings
> - Group settings
> - User settings
> Add:
> ```yaml
> settings:
> theme:
>   base: dark
> ```

References:
- https://github.com/goauthentik/authentik/discussions/7016#discussioncomment-10374755

# Fix password managers

By default authentik prevents password managers from working (¿¿ WTF ??).
But it has a "compatibility mode", which seemingly does nothing, except allowing password managers to work.

- Go to `Admin Interface -> Flows and Stages -> Flows`
- Edit `default-authentication-flow`: `Behavior settings -> Compatibility mode +`
- Repeat for any other flows that you may need

References:
- https://github.com/goauthentik/authentik/discussions/2419

# Icons for apps

References:
- https://github.com/homarr-labs/dashboard-icons

# Increase login timeout

Authentik keeps its own login info in browser cookies.
By default authentik uses cookies with automatic timeout, and browser decides when you need to log in again.

You can adjust this to use a fixed-time session with longer duration:

- `Flow and Stages -> Stages -> default-authentication-login -> Stay signed in offset`.
- - Set to `days=400`
- - Note that max session duration in your browser can be lower than 400 days.
