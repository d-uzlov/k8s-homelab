
# authelia notifications

Notifications are sent on password reset or on 2-factor setup.

# SMTP

- yandex: https://yandex.ru/support/yandex-360/customers/mail/ru/mail-clients/others.html#smtpsetting
- google: https://support.google.com/a/answer/176600?hl=en

Example configuration:

```yaml
notifier:
  smtp:
    address: submissions://smtp.example.com:465
    username: user@example.com
    password: qwe123
    sender: Authelia at Example <user@example.com>
    subject: '[Authelia] {title}'
```

Use `submissions` protocol instead of `smtp`:
- https://github.com/authelia/authelia/discussions/7629
