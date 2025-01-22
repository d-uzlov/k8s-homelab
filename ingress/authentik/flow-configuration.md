
# Authentik flow setup

This file describes how to create and/or configure "flows" for different actions:

- [Create account](#enrollment-creating-account)
- [Password recovery via email](#email-settings)
- [Passwordless auth via WebAuthn]()

# Customize login page

Show password field on the same page instead of checking username first:

- `Flows and Stages -> Flows -> default-authentication-flow`
- - `Stage Bindings -> default-authentication-identification -> Edit Stage`
- - - `Password stage`: select `default-authentication-password`

# Enrollment

References:
- https://www.youtube.com/watch?v=mGOTpRfulfQ
- https://docs.goauthentik.io/docs/users-sources/user/invitations
- https://github.com/goauthentik/authentik/issues/9719

Create account via invitation:

- Download enrollment flow: https://docs.goauthentik.io/assets/files/flows-enrollment-2-stage-11d645d45ab0c1b157aa2f5a9907af4e.yaml
- - Import downloaded flow: `Admin interface -> Flows and Stages -> Flows -> Import`
- - Don't forget to enable compatibility mode for the imported flow
- Create Invitation stage
- - `Admin interface -> Flows and Stages -> Stages -> Create`
- - - Name: `invitation`
- - - Select `Invitation Stage`
- `Admin interface -> Flows and Stages -> Flows -> default-enrollment-flow -> Stage bindings -> Bind existing stage`
- - Stage: `invitation`
- - Order: `0`
- Make newly created users internal (only internal users have access to app list and MFA settings):
- - `Admin interface -> Flows and Stages -> Stages -> Create`
- - - Name: `invitation-user-write`
- - - Type: `User Write Stage`
- - - Select `Always create new users`
- - - Select `User type` to `Internal`

Now you can invite new users to your authentik instance:

- `Admin interface -> Directory -> Invitations -> Create`
- Select your `default-enrollment-flow`
- After invitation is created, it should have arrow to open it on the left
- Open the invitation, copy the `Link to use the invitation`, send it to someone

# email settings

**Note**: there is a regression in 2024.12 which prevents you
from sending emails and generating recover links as admin.
- https://github.com/goauthentik/authentik/issues/12445

You can bypass this by removing the `Authentication` requirement from the `default-recovery-flow`.

---

References:
- https://docs.goauthentik.io/docs/troubleshooting/emails

```bash
# test sending an email
# set address that should receive test email from authentik
address=example@.example.com
kl -n authentik exec -it deployment/authentik-worker -c worker -- ak test_email $address
```

It seems like version 2024.12.1 doesn't have a recovery flow by default.
You can download one from authentik documentation:
`Add and Secure Applications -> Flows and Stages -> Flows -> Defaults and Examples -> Example flows`:
https://docs.goauthentik.io/docs/add-secure-apps/flows-stages/flow/examples/flows

In case documentation has changed, you can find a January 2025 copy of the recovery flow here:
[flows-recovery-email-verification.yaml](./flows-recovery-email-verification-408d6afeff2fbf276bf43a949e332ef6.yaml).

Import and enable this flow in authentik settings:
-  `Admin interface -> Flows and Stages -> Flows -> Import`
-  `Admin interface -> System -> Brands -> authentik-default -> Edit -> Default Flows -> Recovery flow`

You can customize email appearance:
-  `Admin interface -> Flows and Stages -> Flows -> (click on name) default-recovery-flow -> Stage Bindings -> default-recovery-email -> Edit Stage`

Add `Forgot username or password?` button on the main login page:
- `Flows and Stages -> Flows -> default-authentication-flow`
- - `Stage Bindings -> default-authentication-identification -> Edit Stage`
- - - `Flow settings -> Recovery flow`: select `default-recovery-flow`

# Passwordless auth via WebAuthn

References:
- https://www.youtube.com/watch?v=aEpT2fYGwLw
- https://docs.goauthentik.io/docs/add-secure-apps/flows-stages/stages/authenticator_validate/#passwordless-authentication-authentik-2021124

- `Flows and Stages -> Flows -> Create`
- - Name / Title: `Passwordless login`
- - Designation: `Authentication`
- - Slug: `passwordless-login`
- `Flows and Stages -> Flows -> passwordless-login -> Stage Bindings -> Create and bind Stage`
- Choose `Authenticator Validation Stage`
- Stage config:
- - Name: `Passwordless WebAuthn`
- - Device classes: select `WebAuthn Authenticators`
- - Configuration stages: add `default-authenticator-webauthn-setup`
- Binding config:
- - Order: `10`
- For the same flow: `Stage Bindings -> Bind existing stage`
- - Stage: `default-authentication-login`
- - Order: `20`
- `Flows and Stages -> Flows -> default-authentication-flow`
- - `Stage Bindings -> default-authentication-identification -> Edit Stage`
- - - `Flow settings -> Passwordless flow`: select `passwordless-login`

Now the main login page will show the `Use a security key` button.

Optionally forbid using software WebAuthn implementations:

- `Flows and Stages -> Stages -> default-authenticator-webauthn-setup`: Edit
- - `Resident key requirement`: set `Required`
